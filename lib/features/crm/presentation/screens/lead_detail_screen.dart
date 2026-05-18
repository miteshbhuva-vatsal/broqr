import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/domain/entities/lead_activity.dart';
import 'package:cpapp/features/crm/domain/utils/lead_score.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/entities/org_team.dart';
import 'package:cpapp/features/organisation/domain/services/org_permission_service.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/shared/widgets/whatsapp_logo.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  const LeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  final _noteCtrl = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Lead? _getLead() {
    final leads = ref.watch(crmProvider).leads;
    try {
      return leads.firstWhere((l) => l.id == widget.leadId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isAddingNote = true);
    await ref.read(crmProvider.notifier).addNote(widget.leadId, text);
    _noteCtrl.clear();
    setState(() => _isAddingNote = false);
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:+91${phone.replaceAll(RegExp(r'[^0-9]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      ref.read(crmProvider.notifier).logCall(widget.leadId, phone);
    }
  }

  Future<void> _whatsApp(String phone, Lead lead) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final text = Uri.encodeComponent(
      'Hi, following up on our property discussion regarding '
      '${lead.linkedListingCity ?? 'the property'}.',
    );
    final uri = Uri.parse('https://wa.me/91$cleaned?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      ref.read(crmProvider.notifier).logWhatsApp(widget.leadId, phone);
    }
  }

  Future<void> _confirmDelete(Lead lead) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteLead),
        content: Text(
          'Remove ${lead.clientName} from your pipeline? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.done,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(crmProvider.notifier).deleteLead(widget.leadId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lead = _getLead();

    if (lead == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead')),
        body: const Center(child: Text('Lead not found.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lead.clientName,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error,),
            onPressed: () => _confirmDelete(lead),
            tooltip: 'Delete lead',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Lead score banner ──────────────────────────────────
                  Builder(
                    builder: (context) {
                      final liveScore = computeLeadScore(lead);
                      if (liveScore <= 0) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _LeadScoreBanner(score: liveScore, isDark: isDark),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                  // ── Client info card ───────────────────────────────────
                  _SectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.navyLight,
                              child: Text(
                                lead.clientName.isNotEmpty
                                    ? lead.clientName[0].toUpperCase()
                                    : 'C',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lead.clientName,
                                    style: AppTypography.titleSmall.copyWith(
                                      color: isDark
                                          ? AppColors.white
                                          : AppColors.navyDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (lead.clientPhone != null)
                                    Text(
                                      '+91 ${lead.clientPhone}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Priority badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    lead.priority.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: lead.priority.color
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                lead.priority.label,
                                style: AppTypography.labelSmall.copyWith(
                                  color: lead.priority.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Remarks
                        if (lead.remarks != null &&
                            lead.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.gold.withValues(alpha: 0.08)
                                  : AppColors.gold.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.6),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.format_quote_rounded,
                                      size: 13,
                                      color:
                                          AppColors.gold.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'INTEREST / REMARKS',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.gold
                                            .withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  lead.remarks!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.white.withValues(alpha: 0.85)
                                        : AppColors.navyDark
                                            .withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Contact icon buttons
                        if (lead.clientPhone != null) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _IconContactButton(
                                iconWidget: const Icon(Icons.phone_rounded, size: 22, color: AppColors.info),
                                color: AppColors.info,
                                tooltip: 'Call',
                                onTap: () => _callPhone(lead.clientPhone!),
                              ),
                              const SizedBox(width: 12),
                              _IconContactButton(
                                iconWidget: const WhatsAppLogo(size: 22),
                                color: const Color(0xFF25D366),
                                tooltip: 'WhatsApp',
                                onTap: () => _whatsApp(lead.clientPhone!, lead),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Stage selector ─────────────────────────────────────
                  _SectionTitle(AppLocalizations.of(context).pipelineStage,
                      isDark: isDark,),
                  const SizedBox(height: 8),
                  _SectionCard(
                    isDark: isDark,
                    child: _StageSelector(
                      leadId: widget.leadId,
                      current: lead.stage,
                      visitCount: lead.visitCount,
                      onSelect: (s) => ref
                          .read(crmProvider.notifier)
                          .updateStage(widget.leadId, s),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Priority selector ──────────────────────────────────
                  _SectionTitle(AppLocalizations.of(context).priorityLabel,
                      isDark: isDark,),
                  const SizedBox(height: 8),
                  _SectionCard(
                    isDark: isDark,
                    child: Row(
                      children: LeadPriority.values.map((p) {
                        final isSelected = lead.priority == p;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => ref
                                .read(crmProvider.notifier)
                                .updatePriority(widget.leadId, p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(
                                right: p != LeadPriority.high ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? p.color.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isSelected ? p.color : AppColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: p.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      p.label,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isSelected
                                            ? p.color
                                            : AppColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Linked listing ─────────────────────────────────────
                  if (lead.linkedListingCity != null ||
                      lead.linkedListingId != null) ...[
                    const SizedBox(height: 16),
                    _SectionTitle(AppLocalizations.of(context).linkedListing,
                        isDark: isDark,),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final listing = lead.linkedListingId != null
                            ? ref
                                .watch(feedProvider)
                                .listings
                                .where((l) => l.id == lead.linkedListingId)
                                .firstOrNull
                            : null;
                        return GestureDetector(
                          onTap: lead.linkedListingId != null
                              ? () => context.push(
                                    Routes.listingDetail.replaceFirst(
                                      ':listingId',
                                      lead.linkedListingId!,
                                    ),
                                  )
                              : null,
                          child: _SectionCard(
                            isDark: isDark,
                            child: Row(
                              children: [
                                // Thumbnail preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: () {
                                      final imgUrl =
                                          listing?.heroImageUrl.isNotEmpty ==
                                                  true
                                              ? listing!.heroImageUrl
                                              : lead.linkedListingImageUrl;
                                      return imgUrl != null && imgUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: imgUrl,
                                              fit: BoxFit.cover,
                                              memCacheWidth: 200,
                                              placeholder: (_, __) => Container(
                                                color: AppColors.navyLight,
                                              ),
                                              errorWidget: (_, __, ___) =>
                                                  Container(
                                                color: AppColors.navyLight,
                                                child: const Icon(
                                                  Icons.home_work_outlined,
                                                  color: AppColors.gold,
                                                  size: 28,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                color: AppColors.gold
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.home_work_outlined,
                                                color: AppColors.gold,
                                                size: 28,
                                              ),
                                            );
                                    }(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing != null
                                            ? '${listing.location}, ${listing.city}'
                                            : (lead.linkedListingCity ??
                                                'Property'),
                                        style:
                                            AppTypography.labelMedium.copyWith(
                                          color: isDark
                                              ? AppColors.white
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (listing?.propertyType != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          listing!.propertyType!.label,
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        lead.linkedListingPrice ??
                                            listing?.priceLabel ??
                                            '',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: AppColors.gold,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (lead.linkedListingId != null)
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textHint,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  // ── Follow-up reminder ─────────────────────────────────
                  const SizedBox(height: 16),
                  _ReminderCard(lead: lead, isDark: isDark),

                  // ── Assignment (org mode only) ─────────────────────────
                  if (lead.orgId != null) ...[
                    const SizedBox(height: 16),
                    _AssignmentCard(lead: lead, isDark: isDark),
                  ],

                  // ── Notes ──────────────────────────────────────────────
                  const SizedBox(height: 16),
                  _SectionTitle(
                    '${AppLocalizations.of(context).notes} (${lead.notes.length})',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  if (lead.notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        AppLocalizations.of(context).noNotesYetHint,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    )
                  else
                    ...lead.notes.reversed.map(
                      (note) => _NoteItem(
                        note: note,
                        isDark: isDark,
                        onDelete: () => ref
                            .read(crmProvider.notifier)
                            .deleteNote(widget.leadId, note.id),
                      ),
                    ),

                  // ── Activity log ───────────────────────────────────────
                  const SizedBox(height: 16),
                  _ActivityLogSection(
                    leadId: widget.leadId,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Add note bar — WhatsApp style ─────────────────────────────
          Container(
            color: isDark ? AppColors.navyMid : const Color(0xFFEEF0F3),
            padding: EdgeInsets.fromLTRB(
              10,
              8,
              10,
              MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 46),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _noteCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 5,
                            minLines: 3,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                              fontSize: 15,
                            ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context).addANote,
                              hintStyle: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textHint,
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              isDense: false,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                GestureDetector(
                  onTap: _isAddingNote ? null : _addNote,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _isAddingNote
                          ? AppColors.gold.withValues(alpha: 0.6)
                          : AppColors.gold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isAddingNote
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navyDark,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppColors.navyDark,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reminder card ────────────────────────────────────────────────────────────

class _ReminderCard extends ConsumerWidget {
  const _ReminderCard({required this.lead, required this.isDark});
  final Lead lead;
  final bool isDark;

  Color get _statusColor {
    if (lead.isReminderOverdue) return AppColors.error;
    if (lead.isReminderToday) return AppColors.warning;
    return AppColors.success;
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m $ampm';
  }

  Future<void> _pickReminder(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final initDate = lead.reminderAt ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDark,
            onPrimary: AppColors.white,
            secondary: AppColors.gold,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDark,
            onPrimary: AppColors.white,
            secondary: AppColors.gold,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !context.mounted) return;

    final reminderDt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Optional note
    String? note = lead.reminderNote;
    if (context.mounted) {
      final noteCtrl = TextEditingController(text: note);
      final l2 = AppLocalizations.of(context);
      final result = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l2.reminderNoteOptional),
          content: TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Call to confirm site visit',
            ),
            maxLines: 2,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l2.skip),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
              child: Text(l2.save),
            ),
          ],
        ),
      );
      note = result;
    }

    await ref.read(crmProvider.notifier).setReminder(
          leadId: lead.id,
          reminderAt: reminderDt,
          reminderNote: note?.isEmpty ?? true ? null : note,
        );
  }

  Future<void> _clearReminder(WidgetRef ref) async {
    await ref.read(crmProvider.notifier).setReminder(
          leadId: lead.id,
          reminderAt: null,
          reminderNote: null,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasReminder = lead.reminderAt != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).followUpReminder,
              style: AppTypography.labelMedium.copyWith(
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (hasReminder)
              GestureDetector(
                onTap: () => _clearReminder(ref),
                child: Text(
                  AppLocalizations.of(context).clear,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickReminder(context, ref),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasReminder
                  ? _statusColor.withValues(alpha: 0.08)
                  : (isDark ? AppColors.surfaceDark : AppColors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasReminder ? _statusColor : AppColors.border,
                width: hasReminder ? 1.5 : 1,
              ),
            ),
            child: hasReminder
                ? Row(
                    children: [
                      Icon(
                        Icons.alarm_rounded,
                        size: 18,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDateTime(lead.reminderAt!),
                              style: AppTypography.labelMedium.copyWith(
                                color: _statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (lead.reminderNote != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                lead.reminderNote!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textOnDarkSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (lead.isReminderOverdue) ...[
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)
                                    .overdue
                                    .toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 16,
                        color: _statusColor.withValues(alpha: 0.7),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        Icons.add_alarm_rounded,
                        size: 18,
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).setFollowUpReminder,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Assignment card (org mode) ────────────────────────────────────────────────

class _AssignmentCard extends ConsumerWidget {
  const _AssignmentCard({required this.lead, required this.isDark});

  final Lead lead;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(watchOrgTeamsProvider);
    final membersAsync = ref.watch(watchOrgMembersProvider);
    final callerMember = ref.watch(currentOrgMemberProvider).valueOrNull;
    final callerRole = callerMember?.role ?? OrgRole.view;
    final canAssign = OrgPermissionService.canReassignWithinTeam(callerRole);

    final teams = teamsAsync.valueOrNull ?? [];
    final members = membersAsync.valueOrNull ?? [];

    final assignedTeam = teams.where((t) => t.id == lead.teamId).firstOrNull;
    final assignedMember =
        members.where((m) => m.id == lead.assignedTo).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ASSIGNMENT',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            if (canAssign)
              GestureDetector(
                onTap: () => _showAssignSheet(
                  context,
                  ref,
                  teams,
                  members,
                ),
                child: Text(
                  lead.teamId == null && lead.assignedTo == null
                      ? 'Assign'
                      : 'Edit',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.navyMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _AssignChip(
                icon: Icons.groups_outlined,
                label: assignedTeam?.teamName ?? 'No team',
                color: assignedTeam != null
                    ? AppColors.navyMid
                    : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.border,
              ),
              const SizedBox(width: 8),
              _AssignChip(
                icon: Icons.person_outline_rounded,
                label: assignedMember?.brokerName ?? 'Unassigned',
                color: assignedMember != null
                    ? AppColors.navyMid
                    : AppColors.textHint,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAssignSheet(
    BuildContext context,
    WidgetRef ref,
    List<OrgTeam> teams,
    List<OrgMember> members,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignLeadSheet(
        lead: lead,
        teams: teams,
        members: members,
        onSave: (teamId, assignedTo, clearTeam, clearAssigned) async {
          await ref.read(crmProvider.notifier).updateAssignment(
                leadId: lead.id,
                teamId: teamId,
                clearTeamId: clearTeam,
                assignedTo: assignedTo,
                clearAssignedTo: clearAssigned,
              );
        },
      ),
    );
  }
}

class _AssignChip extends StatelessWidget {
  const _AssignChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Assign lead bottom sheet ───────────────────────────────────────────────────

class _AssignLeadSheet extends StatefulWidget {
  const _AssignLeadSheet({
    required this.lead,
    required this.teams,
    required this.members,
    required this.onSave,
  });

  final Lead lead;
  final List<OrgTeam> teams;
  final List<OrgMember> members;
  final Future<void> Function(
    String? teamId,
    String? assignedTo,
    bool clearTeam,
    bool clearAssigned,
  ) onSave;

  @override
  State<_AssignLeadSheet> createState() => _AssignLeadSheetState();
}

class _AssignLeadSheetState extends State<_AssignLeadSheet> {
  String? _teamId;
  String? _assignedTo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _teamId = widget.lead.teamId;
    _assignedTo = widget.lead.assignedTo;
  }

  List<OrgMember> get _teamMembers {
    if (_teamId == null) return widget.members;
    // Show all active members; filter by team not currently tracked
    // (member→team mapping is in subcollection, not on member doc).
    return widget.members.where((m) => m.isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Assign Lead',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.navyDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Team picker
            Text(
              'Team',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            _DropdownTile<String?>(
              value: _teamId,
              hint: 'No team',
              items: [
                const DropdownMenuItem(value: null, child: Text('No team')),
                ...widget.teams.map(
                  (t) => DropdownMenuItem(value: t.id, child: Text(t.teamName)),
                ),
              ],
              onChanged: (v) => setState(() {
                _teamId = v;
                _assignedTo = null;
              }),
            ),
            const SizedBox(height: 16),

            // Member picker
            Text(
              'Assign to',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            _DropdownTile<String?>(
              value: _assignedTo,
              hint: 'Unassigned',
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Unassigned'),
                ),
                ..._teamMembers.map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text(m.brokerName),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _assignedTo = v),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Save Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(
      _teamId,
      _assignedTo,
      _teamId == null && widget.lead.teamId != null,
      _assignedTo == null && widget.lead.assignedTo != null,
    );
    if (mounted) Navigator.pop(context);
  }
}

class _DropdownTile<T> extends StatelessWidget {
  const _DropdownTile({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: AppColors.textHint),
          ),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.isDark, required this.child});
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {required this.isDark});
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _IconContactButton extends StatelessWidget {
  const _IconContactButton({
    required this.iconWidget,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final Widget iconWidget;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );
  }
}

class _StageSelector extends ConsumerStatefulWidget {
  const _StageSelector({
    required this.leadId,
    required this.current,
    required this.visitCount,
    required this.onSelect,
  });

  final String leadId;
  final LeadStage current;
  final int visitCount;
  final ValueChanged<LeadStage> onSelect;

  @override
  ConsumerState<_StageSelector> createState() => _StageSelectorState();
}

class _StageSelectorState extends ConsumerState<_StageSelector> {
  Timer? _undoTimer;
  bool _canUndo = false;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  void _handleVisitedTap() {
    if (_canUndo) {
      _undoTimer?.cancel();
      setState(() => _canUndo = false);
      ref.read(crmProvider.notifier).decrementVisit(widget.leadId);
    } else {
      ref.read(crmProvider.notifier).incrementVisit(widget.leadId);
      setState(() => _canUndo = true);
      _undoTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _canUndo = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LeadStage.values.map((s) {
        final isCurrent = widget.current == s;
        final isVisited = s == LeadStage.viewing;
        final label = isVisited && widget.visitCount > 0
            ? '${s.label} · ${widget.visitCount}'
            : s.label;

        return GestureDetector(
          onTap: () => isVisited ? _handleVisitedTap() : widget.onSelect(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isCurrent
                  ? s.color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent ? s.color : AppColors.border,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: isCurrent ? s.color : AppColors.textSecondary,
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isVisited && _canUndo) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.undo_rounded,
                    size: 12,
                    color: isCurrent ? s.color : AppColors.textHint,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NoteItem extends StatelessWidget {
  const _NoteItem({
    required this.note,
    required this.isDark,
    required this.onDelete,
  });

  final LeadNote note;
  final bool isDark;
  final VoidCallback onDelete;

  String _fmt(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.text,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        isDark ? AppColors.textOnDark : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(note.createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity log section ──────────────────────────────────────────────────────

// ── Lead score banner ──────────────────────────────────────────────────────────

class _LeadScoreBanner extends StatelessWidget {
  const _LeadScoreBanner({required this.score, required this.isDark});
  final int score;
  final bool isDark;

  Color get _color {
    if (score >= 85) return const Color(0xFFE53935);
    if (score >= 65) return AppColors.warning;
    if (score >= 40) return AppColors.gold;
    if (score >= 20) return AppColors.info;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final band = scoreBandLabel(score);
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Score label + big number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: color,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ 100',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Band + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$band Lead',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityLogSection extends ConsumerWidget {
  const _ActivityLogSection({required this.leadId, required this.isDark});
  final String leadId;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(leadActivityProvider(leadId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('ACTIVITY LOG', isDark: isDark),
        const SizedBox(height: 12),
        activityAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (activities) => activities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'No activity recorded yet.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                )
              : Column(
                  children: activities.asMap().entries.map((e) {
                    return _ActivityEntry(
                      activity: e.value,
                      isLast: e.key == activities.length - 1,
                      isDark: isDark,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _ActivityEntry extends StatelessWidget {
  const _ActivityEntry({
    required this.activity,
    required this.isLast,
    required this.isDark,
  });

  final LeadActivity activity;
  final bool isLast;
  final bool isDark;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = activity.type.color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline dot + vertical connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(activity.type.icon, size: 12, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1.5,
                        color: AppColors.border,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (activity.actorName != null &&
                          activity.actorName!.isNotEmpty) ...[
                        Text(
                          activity.actorName!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.navyMid.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      Text(
                        _timeAgo(activity.createdAt),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
