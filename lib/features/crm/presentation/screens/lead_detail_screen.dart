import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';

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
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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
    }
  }

  Future<void> _confirmDelete(Lead lead) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lead?'),
        content: Text(
          'Remove ${lead.clientName} from your pipeline? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
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
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
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
                                color: lead.priority.color
                                    .withValues(alpha: 0.12),
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

                        // Phone action buttons
                        if (lead.clientPhone != null) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.phone_outlined,
                                  label: 'Call',
                                  color: AppColors.info,
                                  onTap: () => _callPhone(lead.clientPhone!),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.chat_rounded,
                                  label: 'WhatsApp',
                                  color: const Color(0xFF25D366),
                                  onTap: () => _whatsApp(
                                    lead.clientPhone!,
                                    lead,
                                  ),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Stage selector ─────────────────────────────────────
                  _SectionTitle('Pipeline Stage', isDark: isDark),
                  const SizedBox(height: 8),
                  _SectionCard(
                    isDark: isDark,
                    child: _StageSelector(
                      current: lead.stage,
                      onSelect: (s) => ref
                          .read(crmProvider.notifier)
                          .updateStage(widget.leadId, s),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Priority selector ──────────────────────────────────
                  _SectionTitle('Priority', isDark: isDark),
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
                                  color: isSelected
                                      ? p.color
                                      : AppColors.border,
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
                  if (lead.linkedListingCity != null || lead.linkedListingId != null) ...[
                    const SizedBox(height: 16),
                    _SectionTitle('Linked Listing', isDark: isDark),
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
                                    child: listing?.heroImageUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: listing!.heroImageUrl,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 200,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.navyLight,
                                            ),
                                            errorWidget: (_, __, ___) => Container(
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
                                              color: AppColors.gold.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.home_work_outlined,
                                              color: AppColors.gold,
                                              size: 28,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing != null
                                            ? '${listing.location}, ${listing.city}'
                                            : (lead.linkedListingCity ?? 'Property'),
                                        style: AppTypography.labelMedium.copyWith(
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
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        listing?.priceLabel ?? lead.linkedListingPrice ?? '',
                                        style: AppTypography.labelSmall.copyWith(
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

                  // ── Notes ──────────────────────────────────────────────
                  const SizedBox(height: 16),
                  _SectionTitle(
                    'Notes (${lead.notes.length})',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  if (lead.notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No notes yet. Add one below.',
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Add note bar (pinned bottom) ───────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  10,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.navyMid : AppColors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add a note…',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isAddingNote ? null : _addNote,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: _isAddingNote
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navyDark,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: AppColors.navyDark,
                            size: 16,
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
      date.year, date.month, date.day, time.hour, time.minute,
    );

    // Optional note
    String? note = lead.reminderNote;
    if (context.mounted) {
      final noteCtrl = TextEditingController(text: note);
      final result = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reminder Note (optional)'),
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
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
              child: const Text('Save'),
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
              'Follow-up Reminder',
              style: AppTypography.labelMedium.copyWith(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            if (hasReminder)
              GestureDetector(
                onTap: () => _clearReminder(ref),
                child: Text(
                  'Clear',
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
                                'OVERDUE',
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
                        'Set a follow-up reminder',
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageSelector extends StatelessWidget {
  const _StageSelector({required this.current, required this.onSelect});
  final LeadStage current;
  final ValueChanged<LeadStage> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LeadStage.values.map((s) {
        final isCurrent = current == s;
        return GestureDetector(
          onTap: () => onSelect(s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isCurrent
                  ? s.color.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent
                    ? s.color
                    : AppColors.border,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Text(
              s.label,
              style: AppTypography.labelSmall.copyWith(
                color: isCurrent ? s.color : AppColors.textSecondary,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
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
                    color: isDark
                        ? AppColors.textOnDark
                        : AppColors.textPrimary,
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
