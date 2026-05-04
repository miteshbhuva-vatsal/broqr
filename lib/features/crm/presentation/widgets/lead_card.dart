import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';

class LeadCard extends ConsumerWidget {
  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    required this.onStageAdvance,
  });

  final Lead lead;
  final VoidCallback onTap;
  final VoidCallback? onStageAdvance;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextStage = lead.stage.nextStage;

    // Look up the linked listing from the feed cache
    final linkedListing = lead.linkedListingId != null
        ? ref
            .watch(feedProvider.select((s) => s.listings))
            .where((l) => l.id == lead.linkedListingId)
            .firstOrNull
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: lead.stage.color, width: 4),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: name + priority + time ─────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6, top: 1),
                              decoration: BoxDecoration(
                                color: lead.priority.color,
                                shape: BoxShape.circle,
                              ),
                            ),
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
                          ],
                        ),
                        if (lead.clientPhone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            lead.clientPhone!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(lead.updatedAt),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Stage badge + estimated value ────────────────────────────
              Row(
                children: [
                  _StageBadge(stage: lead.stage),
                  const Spacer(),
                  if (lead.estimatedValue != null)
                    Text(
                      _formatValue(lead.estimatedValue!),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),

              // ── Linked listing preview ───────────────────────────────────
              if (lead.linkedListingId != null || lead.linkedListingCity != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: lead.linkedListingId != null
                      ? () => context.push(
                            Routes.listingDetail.replaceFirst(
                              ':listingId',
                              lead.linkedListingId!,
                            ),
                          )
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.navyDark.withValues(alpha: 0.6)
                          : AppColors.offWhite,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: linkedListing?.heroImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: linkedListing!.heroImageUrl,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 150,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.navyLight,
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.navyLight,
                                      child: const Icon(
                                        Icons.home_work_outlined,
                                        color: AppColors.gold,
                                        size: 22,
                                      ),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.gold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: const Icon(
                                      Icons.home_work_outlined,
                                      color: AppColors.gold,
                                      size: 22,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                linkedListing != null
                                    ? '${linkedListing.location}, ${linkedListing.city}'
                                    : (lead.linkedListingCity ?? 'Property'),
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (linkedListing?.propertyType != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  linkedListing!.propertyType!.label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                linkedListing?.priceLabel ??
                                    lead.linkedListingPrice ??
                                    '',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (lead.linkedListingId != null)
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: AppColors.textHint,
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              // ── Latest note ──────────────────────────────────────────────
              if (lead.latestNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  lead.latestNote!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // ── Reminder indicator ───────────────────────────────────────
              if (lead.reminderAt != null) ...[
                const SizedBox(height: 6),
                _ReminderChip(lead: lead),
              ],

              // ── Advance stage button ─────────────────────────────────────
              if (nextStage != null && onStageAdvance != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onStageAdvance,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: nextStage.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: nextStage.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: nextStage.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Move to ${nextStage.label}',
                          style: AppTypography.labelSmall.copyWith(
                            color: nextStage.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    return '₹${v.toStringAsFixed(0)}';
  }
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.lead});
  final Lead lead;

  String _label(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) {
      final ago = now.difference(dt);
      if (ago.inMinutes < 60) return 'Overdue ${ago.inMinutes}m ago';
      if (ago.inHours < 24) return 'Overdue ${ago.inHours}h ago';
      return 'Overdue ${ago.inDays}d ago';
    }
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Today ${_time(dt)}';
    if (diff.inDays == 1) return 'Tomorrow ${_time(dt)}';
    return '${dt.day}/${dt.month} ${_time(dt)}';
  }

  String _time(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final overdue = lead.isReminderOverdue;
    final today = lead.isReminderToday;
    final color = overdue
        ? AppColors.error
        : today
            ? AppColors.warning
            : AppColors.success;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.alarm_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          _label(lead.reminderAt!),
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        if (lead.reminderNote != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '· ${lead.reminderNote}',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.stage});
  final LeadStage stage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: stage.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stage.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        stage.label,
        style: AppTypography.labelSmall.copyWith(
          color: stage.color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
