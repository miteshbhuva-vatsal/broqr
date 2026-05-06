import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/core/services/reminder_notification_service.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/data/datasources/crm_remote_datasource.dart';
import 'package:cpapp/features/crm/data/repositories/crm_repository_impl.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/domain/repositories/crm_repository.dart';

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

// ── CRM state ─────────────────────────────────────────────────────────────────

class CrmState {
  const CrmState({
    this.leads = const [],
    this.isLoading = false,
    this.stageFilter,
    this.error,
  });

  final List<Lead> leads;
  final bool isLoading;
  final LeadStage? stageFilter;
  final String? error;

  List<Lead> get filtered => stageFilter == null
      ? leads
      : leads.where((l) => l.stage == stageFilter).toList();

  int countForStage(LeadStage s) =>
      leads.where((l) => l.stage == s).length;

  int get activeCount =>
      leads.where((l) => l.stage.isActive).length;

  int get closedCount =>
      leads.where((l) => l.stage == LeadStage.closed).length;

  double get pipelineValue => leads
      .where((l) => l.stage.isActive)
      .fold(0.0, (sum, l) => sum + (l.estimatedValue ?? 0));

  int leadsForListing(String listingId) =>
      leads.where((l) => l.linkedListingId == listingId).length;

  CrmState copyWith({
    List<Lead>? leads,
    bool? isLoading,
    LeadStage? stageFilter,
    bool clearFilter = false,
    String? error,
    bool clearError = false,
  }) {
    return CrmState(
      leads: leads ?? this.leads,
      isLoading: isLoading ?? this.isLoading,
      stageFilter:
          clearFilter ? null : (stageFilter ?? this.stageFilter),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── CRM notifier ──────────────────────────────────────────────────────────────

@riverpod
class Crm extends _$Crm {
  @override
  CrmState build() {
    Future.microtask(() => _loadLeads());
    return const CrmState(isLoading: true);
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _loadLeads() async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    final result = await ref.read(crmRepositoryProvider).fetchLeads(uid);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (leads) => state = state.copyWith(
        isLoading: false,
        leads: leads,
        clearError: true,
      ),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadLeads();
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  void setFilter(LeadStage? stage) {
    state = state.copyWith(
      stageFilter: stage,
      clearFilter: stage == null,
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
  }) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
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
        );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (lead) {
        state = state.copyWith(leads: [lead, ...state.leads]);
        return true;
      },
    );
  }

  // ── Update stage ───────────────────────────────────────────────────────────

  Future<void> updateStage(String leadId, LeadStage stage) async {
    // Optimistic update
    _updateLeadInState(leadId, (l) => l.copyWith(stage: stage));

    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          stage: stage,
        );
    result.fold(
      (failure) {
        // Revert on failure by reloading
        _loadLeads();
        state = state.copyWith(error: failure.message);
      },
      (updated) => _updateLeadInState(leadId, (_) => updated),
    );
  }

  // ── Update priority ────────────────────────────────────────────────────────

  Future<void> updatePriority(String leadId, LeadPriority priority) async {
    _updateLeadInState(leadId, (l) => l.copyWith(priority: priority));

    final result = await ref.read(crmRepositoryProvider).updateLead(
          leadId: leadId,
          priority: priority,
        );
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) => _updateLeadInState(leadId, (_) => updated),
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
    final result =
        await ref.read(crmRepositoryProvider).addNote(leadId: leadId, text: text);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (updated) => _updateLeadInState(leadId, (_) => updated),
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
          id: leadId, ownerUid: '', clientName: '', stage: LeadStage.newLead,
          priority: LeadPriority.medium, notes: const [], createdAt: DateTime.now(),
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
      (updated) => _updateLeadInState(leadId, (_) => updated),
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteLead(String leadId) async {
    state = state.copyWith(
      leads: state.leads.where((l) => l.id != leadId).toList(),
    );
    final result =
        await ref.read(crmRepositoryProvider).deleteLead(leadId);
    result.fold(
      (failure) {
        _loadLeads();
        state = state.copyWith(error: failure.message);
      },
      (_) {},
    );
  }

  // ── Helper ─────────────────────────────────────────────────────────────────

  void _updateLeadInState(String leadId, Lead Function(Lead) updater) {
    state = state.copyWith(
      leads: state.leads.map((l) => l.id == leadId ? updater(l) : l).toList(),
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
