import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leads = ref.watch(reminderLeadsProvider);
    final isLoading = ref.watch(crmProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.alarm_rounded, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).reminders,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            )
          : leads.isEmpty
              ? _EmptyState(isDark: isDark)
              : RefreshIndicator(
                  onRefresh: () => ref.read(crmProvider.notifier).refresh(),
                  color: AppColors.gold,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    itemCount: leads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _ReminderTile(
                      lead: leads[i],
                      isDark: isDark,
                      onTap: () => context.push(
                        Routes.leadDetail.replaceFirst(':leadId', leads[i].id),
                      ),
                      onClear: () => ref
                          .read(crmProvider.notifier)
                          .setReminder(leadId: leads[i].id),
                    ),
                  ),
                ),
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.lead,
    required this.isDark,
    required this.onTap,
    required this.onClear,
  });

  final Lead lead;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onClear;

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
    return '${dt.day} ${months[dt.month - 1]} · $h:$m $ampm';
  }

  String _relativeLabel(DateTime dt) {
    if (lead.isReminderOverdue) {
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return 'Overdue ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Overdue ${diff.inHours}h ago';
      return 'Overdue ${diff.inDays}d ago';
    }
    if (lead.isReminderToday) {
      final diff = dt.difference(DateTime.now());
      if (diff.inMinutes < 60) return 'In ${diff.inMinutes} min';
      return 'Today in ${diff.inHours}h';
    }
    final diff = dt.difference(DateTime.now());
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 7) return 'In ${diff.inDays} days';
    return 'In ${(diff.inDays / 7).floor()}w';
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    final reminderDt = lead.reminderAt!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : AppColors.navyDark.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.alarm_rounded, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lead.clientName,
                            style: AppTypography.titleSmall.copyWith(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _relativeLabel(reminderDt),
                            style: AppTypography.labelSmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatDateTime(reminderDt),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (lead.reminderNote != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        lead.reminderNote!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textHint,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: lead.stage.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            lead.stage.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: lead.stage.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (lead.linkedListingCity != null) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.link_rounded,
                            size: 11,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            lead.linkedListingCity!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Clear button
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.alarm_off_rounded,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alarm_off_rounded,
              size: 72,
              color: AppColors.gold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).noRemindersSet,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).setReminderHint,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
