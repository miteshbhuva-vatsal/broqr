import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/features/crm/domain/utils/lead_score.dart';
import 'package:cpapp/core/services/reminder_notification_service.dart';
import 'package:cpapp/core/services/whatsapp_webhook_service.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/data/datasources/crm_remote_datasource.dart';
import 'package:cpapp/features/crm/data/repositories/crm_repository_impl.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/domain/entities/lead_activity.dart';
import 'package:cpapp/features/crm/domain/repositories/crm_repository.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';

part 'crm_providers.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

@riverpod
CrmRemoteDataSource crmRemoteDataSource(Ref ref) {
  return CrmRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
CrmRepository crmRepository(Ref ref) {
  return CrmRepositoryImpl(
    dataSource: ref.watch(crmRemoteDataSourceProvider),
  );
}

// ── Activity log stream ───────────────────────────────────────────────────────

final leadActivityProvider =
    StreamProvider.autoDispose.family<List<LeadActivity>, String>(
  (ref, leadId) => ref.watch(crmRepositoryProvider).watchActivity(leadId),
);

// ── CRM state ─────────────────────────────────────────────────────────────────

class CrmState {
  CrmState({
    this.streamLeads = const [],
    this.olderLeads = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.stageFilter,
    this.visitedFilter = false,
    this.error,
    this.callerRole,
    this.callerUid,
    this.callerMemberId,
    this.callerTeamIds = const [],
    this.teamLeadsShared = false,
  });

  /// Live-updated most-recent page (driven by Firestore stream).
  final List<Lead> streamLeads;

  /// One-shot paginated older pages, kept across stream re-emissions.
  final List<Lead> olderLeads;

  final bool isLoading;
  final bool isLoadingMore;

  /// True until a paginated fetch returns fewer than the requested page size,
  /// indicating no more older leads exist.
  final bool hasMore;

  final LeadStage? stageFilter;

  /// When true, show only leads with visitCount >= 1 (cross-cutting, ignores stage).
  final bool visitedFilter;

  final String? error;

  /// Org context — null = solo mode.
  final OrgRole? callerRole;
  final String? callerUid;

  /// Deterministic org_members doc id (`{uid}_{orgId}`), used to match
  /// `lead.assignedTo` for the agent/view scope filter.
  final String? callerMemberId;
  final List<String> callerTeamIds;

  /// When true all org members see all org leads (admin toggled sharing on).
  final bool teamLeadsShared;

  bool get isOrgMode => callerRole != null;

  /// Merged stream + older with id-dedup, filtered to caller's scope.
  late final List<Lead> leads = _merge();

  List<Lead> _merge() {
    // Deduplicate by id across both lists: streamLeads win over olderLeads,
    // and duplicates within olderLeads (pagination overlap) are also removed.
    final seen = <String>{};
    final all = <Lead>[];
    for (final l in [...streamLeads, ...olderLeads]) {
      if (seen.add(l.id)) all.add(l);
    }

    // Admin always sees everything.
    if (callerRole == OrgRole.admin) return all;

    // When admin has enabled cross-team sharing, all members see all org leads.
    if (teamLeadsShared && isOrgMode) return all;

    // Manager: own leads + leads in their teams.
    if (callerRole == OrgRole.manager && callerUid != null) {
      return all
          .where(
            (l) =>
                l.ownerUid == callerUid ||
                (l.teamId != null && callerTeamIds.contains(l.teamId)),
          )
          .toList();
    }

    // Agent / View: own leads + leads explicitly assigned to this member.
    if ((callerRole == OrgRole.agent || callerRole == OrgRole.view) &&
        callerUid != null) {
      return all
          .where(
            (l) =>
                l.ownerUid == callerUid ||
                (callerMemberId != null && l.assignedTo == callerMemberId),
          )
          .toList();
    }

    return all;
  }

  List<Lead> get filtered {
    if (visitedFilter) return leads.where((l) => l.visitCount >= 1).toList();
    if (stageFilter != null) return leads.where((l) => l.stage == stageFilter).toList();
    return leads;
  }

  int get visitedCount => leads.where((l) => l.visitCount >= 1).length;

  int countForStage(LeadStage s) => leads.where((l) => l.stage == s).length;

  int get activeCount => leads.where((l) => l.stage.isActive).length;

  int get closedCount => leads.where((l) => l.stage == LeadStage.closed).length;

  /// Total estimated value across active leads visible in the current view.
  /// When a stage filter is active, only that stage's leads are counted so the
  /// stat always matches what the user sees on screen.
  double get pipelineValue {
    final source = (stageFilter != null && stageFilter!.isActive)
        ? filtered
        : leads.where((l) => l.stage.isActive).toList();
    return source.fold(0.0, (sum, l) => sum + _leadValue(l));
  }

  /// Number of active leads that have a value contributing to [pipelineValue].
  int get pipelineLeadCount {
    final source = (stageFilter != null && stageFilter!.isActive)
        ? filtered
        : leads.where((l) => l.stage.isActive).toList();
    return source.where((l) => _leadValue(l) > 0).length;
  }

  /// Authoritative value for a lead: listing price (parsed) for linked leads,
  /// falling back to estimatedValue, then 0.
  static double _leadValue(Lead l) {
    if (l.linkedListingId != null) {
      final parsed = _parsePriceLabel(l.linkedListingPrice);
      if (parsed != null) return parsed;
    }
    return l.estimatedValue ?? 0;
  }

  /// Parse formatted price labels like "₹25.00 L" or "₹1.2 Cr" to a number.
  static double? _parsePriceLabel(String? s) {
    if (s == null || s.isEmpty) return null;
    final cleaned = s.replaceAll('₹', '').replaceAll(',', '').trim();
    if (cleaned.endsWith(' Cr')) {
      final v = double.tryParse(cleaned.substring(0, cleaned.length - 3).trim());
      return v != null ? v * 10000000 : null;
    }
    if (cleaned.endsWith(' L')) {
      final v = double.tryParse(cleaned.substring(0, cleaned.length - 2).trim());
      return v != null ? v * 100000 : null;
    }
    return double.tryParse(cleaned);
  }

  int leadsForListing(String listingId) =>
      leads.where((l) => l.linkedListingId == listingId).length;

  CrmState copyWith({
    List<Lead>? streamLeads,
    List<Lead>? olderLeads,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    LeadStage? stageFilter,
    bool clearFilter = false,
    bool? visitedFilter,
    String? error,
    bool clearError = false,
    OrgRole? callerRole,
    String? callerUid,
    String? callerMemberId,
    List<String>? callerTeamIds,
    bool? teamLeadsShared,
  }) {
    return CrmState(
      streamLeads: streamLeads ?? this.streamLeads,
      olderLeads: olderLeads ?? this.olderLeads,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      stageFilter: clearFilter ? null : (stageFilter ?? this.stageFilter),
      visitedFilter: visitedFilter ?? (clearFilter ? false : this.visitedFilter),
      error: clearError ? null : (error ?? this.error),
      callerRole: callerRole ?? this.callerRole,
      callerUid: callerUid ?? this.callerUid,
      callerMemberId: callerMemberId ?? this.callerMemberId,
      callerTeamIds: callerTeamIds ?? this.callerTeamIds,
      teamLeadsShared: teamLeadsShared ?? this.teamLeadsShared,
    );
  }
}

// ── CRM notifier ──────────────────────────────────────────────────────────────

@riverpod
class Crm extends _$Crm {
  @override
  CrmState build() {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    final orgId = ref.watch(currentOrgIdProvider);
    final member = ref.watch(currentOrgMemberProvider).valueOrNull;
    final teamIds = ref.watch(callerTeamIdsProvider).valueOrNull ?? [];
    final org = ref.watch(watchCurrentOrgProvider).valueOrNull;
    final teamLeadsShared = org?.teamLeadsShared ?? false;

    if (uid.isNotEmpty) {
      final ds = ref.read(crmRemoteDataSourceProvider);
      // All org members (including agents/view) use the org-wide stream so
      // assigned leads from other owners are visible; _merge() filters to scope.
      final stream = orgId != null
          ? ds.watchRecentOrgLeads(orgId)
          : ds.watchRecentLeads(uid);

      final sub = stream.listen(
        (leads) => state = state.copyWith(
          isLoading: false,
          streamLeads: leads,
          clearError: true,
        ),
        onError: (Object e) => state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
      ref.onDispose(sub.cancel);
    }

    return CrmState(
      isLoading: uid.isNotEmpty,
      callerRole: member?.role,
      callerUid: uid,
      callerMemberId: member?.id,
      callerTeamIds: teamIds,
      teamLeadsShared: teamLeadsShared,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      olderLeads: const [],
      hasMore: true,
      clearError: true,
    );
    ref.invalidateSelf();
  }

  /// Loads the next batch of older leads (one-shot, paginated).
  Future<void> loadOlder() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;

    final cursor = state.leads.isEmpty ? null : state.leads.last.updatedAt;
    if (cursor == null) return;

    state = state.copyWith(isLoadingMore: true);
    const pageSize = 30;

    final orgId = ref.read(currentOrgIdProvider);

    final Either<dynamic, List<Lead>> result;
    if (orgId != null) {
      result = await ref.read(crmRepositoryProvider).fetchOlderOrgLeads(
            orgId: orgId,
            beforeUpdatedAt: cursor,
            limit: pageSize,
          );
    } else {
      result = await ref.read(crmRepositoryProvider).fetchOlderLeads(
            ownerUid: uid,
            beforeUpdatedAt: cursor,
            limit: pageSize,
          );
    }

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      ),
      (older) => state = state.copyWith(
        isLoadingMore: false,
        olderLeads: [...state.olderLeads, ...older],
        hasMore: older.length >= pageSize,
      ),
    );
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void setFilter(LeadStage? stage) {
    state = state.copyWith(
      stageFilter: stage,
      clearFilter: stage == null,
      visitedFilter: false,
    );
  }

  void setVisitedFilter(bool enabled) {
    state = state.copyWith(
      visitedFilter: enabled,
      clearFilter: enabled,
    );
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<bool> createLead({
    required String clientName,
    required LeadStage stage,
    required LeadPriority priority,
    String? clientPhone,
    double? estimatedValue,
    String? linkedListingId,
    String? linkedListingCity,
    String? linkedListingPrice,
    String? linkedListingImageUrl,
    String? remarks,
    LeadSource source = LeadSource.added,
  }) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    final orgId = ref.read(currentOrgIdProvider);
    final result = await ref.read(crmRepositoryProvider).createLead(
          ownerUid: uid,
          clientName: clientName,
          stage: stage,
          priority: priority,
          clientPhone: clientPhone,
          estimatedValue: estimatedValue,
          linkedListingId: linkedListingId,
          linkedListingCity: linkedListingCity,
          linkedListingPrice: linkedListingPrice,
          linkedListingImageUrl: linkedListingImageUrl,
          remarks: remarks,
          source: source,
          orgId: orgId,
        );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (lead) {
        state = state.copyWith(
          streamLeads: [lead, ...state.streamLeads],
        );
        final desc = source == LeadSource.contacted
            ? 'Lead added via listing contact'
            : 'Lead added by ${_actorName()}';
        _logAndScore(lead.id, lead, LeadActivityType.leadCreated, desc);
        if (remarks != null && remarks.isNotEmpty) {
          _logAndScore(
            lead.id,
            lead,
            LeadActivityType.remarkAdded,
            'Remark: "${remarks.length > 60 ? '${remarks.substring(0, 60)}…' : remarks}"',
          );
        }
        return true;
      },
    );
  }

  // ── Visit counter ──────────────────────────────────────────────────────────

  Future<void> incrementVisit(String leadId) async {
    final lead = state.leads.where((l) => l.id == leadId).firstOrNull;
    if (lead == null) return;
    final newCount = lead.visitCount + 1;
    _updateLeadInState(leadId, (l) => l.copyWith(visitCount: newCount));
    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          visitCount: newCount,
          stage: lead.stage == LeadStage.viewing ? null : LeadStage.viewing,
        );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) {
        _updateLeadInState(leadId, (_) => updated);
        _logAndScore(
          leadId,
          updated,
          LeadActivityType.stageChanged,
          'Client visited property · Visit #$newCount',
          meta: {'visitCount': newCount},
        );
      },
    );
  }

  Future<void> decrementVisit(String leadId) async {
    final lead = state.leads.where((l) => l.id == leadId).firstOrNull;
    if (lead == null || lead.visitCount <= 0) return;
    final newCount = lead.visitCount - 1;
    _updateLeadInState(leadId, (l) => l.copyWith(visitCount: newCount));
    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          visitCount: newCount,
        );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) => _updateLeadInState(leadId, (_) => updated),
    );
  }

  // ── Update stage ───────────────────────────────────────────────────────────

  Future<void> updateStage(String leadId, LeadStage stage) async {
    final prior =
        state.leads.where((l) => l.id == leadId).firstOrNull?.stage;
    _updateLeadInState(leadId, (l) => l.copyWith(stage: stage));

    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          stage: stage,
        );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) {
        _updateLeadInState(leadId, (_) => updated);
        if (prior != null && prior != stage) {
          _logAndScore(
            leadId,
            updated,
            LeadActivityType.stageChanged,
            'Stage: ${prior.label} → ${stage.label}',
            meta: {'fromStage': prior.firestoreKey, 'toStage': stage.firestoreKey},
          );
        }
      },
    );
  }

  // ── Update priority ────────────────────────────────────────────────────────

  Future<void> updatePriority(String leadId, LeadPriority priority) async {
    final prior =
        state.leads.where((l) => l.id == leadId).firstOrNull?.priority;
    _updateLeadInState(leadId, (l) => l.copyWith(priority: priority));

    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          priority: priority,
        );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) {
        _updateLeadInState(leadId, (_) => updated);
        if (prior != null && prior != priority) {
          _logAndScore(
            leadId,
            updated,
            LeadActivityType.priorityChanged,
            'Priority changed to ${priority.label}',
          );
        }
      },
    );
  }

  // ── Assign to team / member ────────────────────────────────────────────────

  Future<bool> updateAssignment({
    required String leadId,
    String? teamId,
    bool clearTeamId = false,
    String? assignedTo,
    bool clearAssignedTo = false,
  }) async {
    // Capture before optimistic update so we have the original lead data.
    final lead = state.leads.where((l) => l.id == leadId).firstOrNull;

    _updateLeadInState(
      leadId,
      (l) => l.copyWith(
        teamId: clearTeamId ? null : (teamId ?? l.teamId),
        assignedTo: clearAssignedTo ? null : (assignedTo ?? l.assignedTo),
      ),
    );
    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          teamId: teamId,
          clearTeamId: clearTeamId,
          assignedTo: assignedTo,
          clearAssignedTo: clearAssignedTo,
        );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (updated) {
        _updateLeadInState(leadId, (_) => updated);

        // Resolve names for logging + WhatsApp notification.
        final teams = ref.read(watchOrgTeamsProvider).valueOrNull ?? [];
        final members = ref.read(watchOrgMembersProvider).valueOrNull ?? [];
        final teamName = teamId != null
            ? teams.where((t) => t.id == teamId).firstOrNull?.teamName
            : null;
        final memberName = assignedTo != null
            ? members.where((m) => m.id == assignedTo).firstOrNull?.brokerName
            : null;

        // Activity log
        final String logDesc;
        if (clearTeamId && clearAssignedTo) {
          logDesc = 'Assignment cleared';
        } else {
          final parts = <String>[
            if (teamName != null) teamName,
            if (memberName != null) '→ $memberName',
          ];
          logDesc =
              parts.isNotEmpty ? parts.join(' ') : 'Lead assigned';
        }
        _logAndScore(leadId, updated, LeadActivityType.leadAssigned, logDesc);

        // Fire WhatsApp notification when assigning to a member (not clearing).
        if (assignedTo != null && !clearAssignedTo && lead != null) {
          final assigneeName = memberName ?? assignedTo;
          unawaited(
            WhatsAppWebhookService.notifyLeadAssigned(
              clientName: lead.clientName,
              clientPhone: lead.clientPhone,
              assigneeName: assigneeName,
            ),
          );
        }

        return true;
      },
    );
  }

  // ── Update client info ─────────────────────────────────────────────────────

  Future<bool> updateClientInfo({
    required String leadId,
    required String clientName,
    String? clientPhone,
  }) async {
    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          clientName: clientName,
          clientPhone: clientPhone,
        );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (updated) {
        _updateLeadInState(leadId, (_) => updated);
        return true;
      },
    );
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  Future<void> addNote(String leadId, String text) async {
    final result = await ref
        .read(crmRepositoryProvider)
        .addNote(leadId: leadId, text: text);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) {
        _updateLeadInState(leadId, (_) => updated);
        _logAndScore(leadId, updated, LeadActivityType.noteAdded, 'Note added');
      },
    );
  }

  Future<void> deleteNote(String leadId, String noteId) async {
    // Optimistic update
    _updateLeadInState(
      leadId,
      (l) => l.copyWith(
        notes: l.notes.where((n) => n.id != noteId).toList(),
      ),
    );

    final result = await ref.read(crmRepositoryProvider).deleteNote(
          leadId: leadId,
          noteId: noteId,
        );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) => _updateLeadInState(leadId, (_) => updated),
    );
  }

  // ── Reminder ───────────────────────────────────────────────────────────────

  Future<void> setReminder({
    required String leadId,
    DateTime? reminderAt,
    String? reminderNote,
  }) async {
    _updateLeadInState(
      leadId,
      (l) => l.copyWith(
        reminderAt: reminderAt,
        clearReminder: reminderAt == null,
        reminderNote: reminderNote,
        clearReminderNote: reminderNote == null,
      ),
    );

    // Schedule or cancel the local 1-hour-early notification
    if (reminderAt != null) {
      final lead = state.leads.firstWhere(
        (l) => l.id == leadId,
        orElse: () => Lead(
          id: leadId,
          ownerUid: '',
          clientName: '',
          stage: LeadStage.newLead,
          priority: LeadPriority.medium,
          notes: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      ReminderNotificationService.schedule(
        leadId: leadId,
        clientName: lead.clientName,
        reminderAt: reminderAt,
      );
    } else {
      ReminderNotificationService.cancel(leadId);
    }

    final result = await ref.read(crmRepositoryProvider).setReminder(
          leadId: leadId,
          reminderAt: reminderAt,
          reminderNote: reminderNote,
        );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) {
        _updateLeadInState(leadId, (_) => updated);
        if (reminderAt != null) {
          final months = [
            'Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec',
          ];
          final h = reminderAt.hour % 12 == 0 ? 12 : reminderAt.hour % 12;
          final m = reminderAt.minute.toString().padLeft(2, '0');
          final ampm = reminderAt.hour < 12 ? 'AM' : 'PM';
          final dateStr =
              '${reminderAt.day} ${months[reminderAt.month - 1]}, $h:$m $ampm';
          _logAndScore(
            leadId,
            updated,
            LeadActivityType.callScheduled,
            'Follow-up scheduled: $dateStr'
            '${reminderNote != null && reminderNote.isNotEmpty ? ' · $reminderNote' : ''}',
          );
        }
      },
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteLead(String leadId) async {
    // Lead may live in either streamLeads or olderLeads — prune from both.
    state = state.copyWith(
      streamLeads: state.streamLeads.where((l) => l.id != leadId).toList(),
      olderLeads: state.olderLeads.where((l) => l.id != leadId).toList(),
    );
    final result = await ref.read(crmRepositoryProvider).deleteLead(leadId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {},
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _actorName() =>
      ref.read(currentOrgMemberProvider).valueOrNull?.brokerName ??
      ref.read(authStateChangesProvider).valueOrNull?.name ??
      '';

  void _logAndScore(
    String leadId,
    Lead lead,
    LeadActivityType type,
    String description, {
    Map<String, dynamic>? meta,
  }) {
    final score = computeLeadScore(lead);
    final prevScore = lead.leadScore;
    final delta = score - prevScore;
    final metadata = <String, dynamic>{
      'leadScore': score,
      if (delta != 0) 'scoreDelta': delta,
      ...?meta,
    };
    _updateLeadInState(
      leadId,
      (l) => l.copyWith(leadScore: score, touchpointCount: l.touchpointCount + 1),
    );
    unawaited(
      ref.read(crmRepositoryProvider).addActivity(
            leadId: leadId,
            type: type,
            description: description,
            actorName: _actorName(),
            metadata: metadata,
            leadScore: score,
          ),
    );
  }

  /// Called from UI after a successful call launch.
  void logCall(String leadId, String phone) {
    final lead = state.leads.where((l) => l.id == leadId).firstOrNull;
    if (lead == null) return;
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.period == DayPeriod.am ? 'AM' : 'PM';
    _logAndScore(leadId, lead, LeadActivityType.callMade, 'Call made · $h:$m $ampm');
  }

  /// Called from UI after a successful WhatsApp launch.
  void logWhatsApp(String leadId, String phone) {
    final lead = state.leads.where((l) => l.id == leadId).firstOrNull;
    if (lead == null) return;
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.period == DayPeriod.am ? 'AM' : 'PM';
    _logAndScore(
      leadId,
      lead,
      LeadActivityType.messageSent,
      'WhatsApp sent · +91 $phone · $h:$m $ampm',
    );
  }

  void _updateLeadInState(String leadId, Lead Function(Lead) updater) {
    state = state.copyWith(
      streamLeads: state.streamLeads
          .map((l) => l.id == leadId ? updater(l) : l)
          .toList(),
      olderLeads:
          state.olderLeads.map((l) => l.id == leadId ? updater(l) : l).toList(),
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Derived reminder providers ────────────────────────────────────────────────

/// All leads with a reminder set, sorted: overdue first, then by soonest.
final reminderLeadsProvider = Provider<List<Lead>>((ref) {
  final leads = ref.watch(crmProvider).leads;
  final withReminder = leads.where((l) => l.reminderAt != null).toList();
  withReminder.sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
  return withReminder;
});

/// Count of overdue + today reminders for the badge.
final urgentReminderCountProvider = Provider<int>((ref) {
  return ref
      .watch(reminderLeadsProvider)
      .where((l) => l.isReminderOverdue || l.isReminderToday)
      .length;
});
