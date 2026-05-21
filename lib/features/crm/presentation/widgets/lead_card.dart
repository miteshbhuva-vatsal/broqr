import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/domain/utils/lead_score.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/shared/widgets/whatsapp_logo.dart';

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

  // Stage progress 0..1
  double get _progress => switch (lead.stage) {
        LeadStage.newLead => 0.0,
        LeadStage.contacted => 0.2,
        LeadStage.viewing => 0.4,
        LeadStage.negotiating => 0.65,
        LeadStage.closed => 1.0,
        LeadStage.lost => 1.0,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  String _formatValue(double v) {
    if (v >= 10000000) return '₹${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    return '₹${v.toStringAsFixed(0)}';
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:+91${phone.replaceAll(RegExp(r'[^0-9]'), '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/91$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final liveScore = computeLeadScore(lead);
    final nextStage = lead.stage.nextStage;
    final isLost = lead.stage == LeadStage.lost;
    final stageColor = lead.stage.color;

    final linkedListing = lead.linkedListingId != null
        ? ref
            .watch(feedProvider.select((s) => s.listings))
            .where((l) => l.id == lead.linkedListingId)
            .firstOrNull
        : null;

    // Resolve team/member names + manager name
    String? teamName;
    String? assigneeName;
    final members = lead.orgId != null
        ? (ref.watch(watchOrgMembersProvider).valueOrNull ?? [])
        : <dynamic>[];
    if (lead.orgId != null) {
      final teams = ref.watch(watchOrgTeamsProvider).valueOrNull ?? [];
      if (lead.teamId != null) {
        teamName = teams
            .where((t) => t.id == lead.teamId)
            .firstOrNull
            ?.teamName;
      }
      if (lead.assignedTo != null) {
        assigneeName = members
            .where((m) => m.id == lead.assignedTo)
            .firstOrNull
            ?.brokerName as String?;
      }
    }
    // Manager = assignee if set, else the person who owns the lead (self)
    final selfName = ref.watch(currentOrgMemberProvider).valueOrNull?.brokerName
        ?? ref.watch(authStateChangesProvider).valueOrNull?.name;
    final managerName = assigneeName ?? selfName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.18)
                  : AppColors.navyDark.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stage colour stripe
                Container(width: 4, color: stageColor),

                // Card body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Row 1: name + priority + age ──────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Priority dot
                            Padding(
                              padding: const EdgeInsets.only(top: 4, right: 6),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: lead.priority.color,
                                  shape: BoxShape.circle,
                                ),
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
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeAgo(lead.updatedAt),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                            if (liveScore > 0) ...[
                              const SizedBox(width: 6),
                              _ScoreBadge(score: liveScore),
                            ],
                          ],
                        ),

                        // ── Phone ──────────────────────────────────────────
                        if (lead.clientPhone != null) ...[
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 14),
                            child: Text(
                              '+91 ${lead.clientPhone}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],

                        // ── Remarks callout ────────────────────────────────
                        if (lead.remarks != null &&
                            lead.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.gold.withValues(alpha: 0.08)
                                  : AppColors.gold.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.gold.withValues(alpha: 0.6),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.format_quote_rounded,
                                    size: 14,
                                    color: AppColors.gold
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    lead.remarks!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.gold
                                              .withValues(alpha: 0.9)
                                          : AppColors.navyDark
                                              .withValues(alpha: 0.75),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // ── Stage progress bar + value ─────────────────────
                        Row(
                          children: [
                            // Stage label pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: stageColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: stageColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                lead.stage == LeadStage.viewing &&
                                        lead.visitCount > 0
                                    ? '${lead.stage.label} · ${lead.visitCount}'
                                    : lead.stage.label,
                                style: AppTypography.labelSmall.copyWith(
                                  color: stageColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Progress bar
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: SizedBox(
                                  height: 4,
                                  child: isLost
                                      ? Container(
                                          color: AppColors.error
                                              .withValues(alpha: 0.25),
                                        )
                                      : LinearProgressIndicator(
                                          value: _progress,
                                          backgroundColor:
                                              AppColors.border,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            stageColor,
                                          ),
                                          minHeight: 4,
                                        ),
                                ),
                              ),
                            ),

                            // Estimated value
                            if (lead.estimatedValue != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatValue(lead.estimatedValue!),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),

                        // ── Assignment chip ────────────────────────────────
                        if (teamName != null || managerName != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (teamName != null) ...[
                                Icon(
                                  Icons.groups_2_outlined,
                                  size: 11,
                                  color: AppColors.navyMid.withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  teamName,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.navyMid,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                                if (managerName != null)
                                  Text(
                                    ' · ',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textHint,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                              if (managerName != null) ...[
                                Icon(
                                  assigneeName != null
                                      ? Icons.person_outline
                                      : Icons.manage_accounts_outlined,
                                  size: 11,
                                  color: AppColors.navyMid.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  assigneeName != null
                                      ? managerName
                                      : 'By $managerName',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.navyMid.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],

                        // ── Linked listing ─────────────────────────────────
                        if (lead.linkedListingId != null ||
                            lead.linkedListingCity != null) ...[
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
                                    ? AppColors.navyDark.withValues(alpha: 0.5)
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: () {
                                        final imgUrl =
                                            linkedListing?.heroImageUrl
                                                .isNotEmpty == true
                                            ? linkedListing!.heroImageUrl
                                            : lead.linkedListingImageUrl;
                                        return imgUrl != null &&
                                                imgUrl.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: imgUrl,
                                                fit: BoxFit.cover,
                                                memCacheWidth: 130,
                                                placeholder: (_, __) =>
                                                    Container(
                                                  color: AppColors.navyLight,
                                                ),
                                                errorWidget: (_, __, ___) =>
                                                    _ListingIcon(),
                                              )
                                            : _ListingIcon();
                                      }(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          linkedListing != null
                                              ? '${linkedListing.location}, ${linkedListing.city}'
                                              : (lead.linkedListingCity ??
                                                  'Property'),
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: isDark
                                                ? AppColors.white
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          lead.linkedListingPrice ??
                                              linkedListing?.priceLabel ??
                                              '',
                                          style: AppTypography.labelSmall
                                              .copyWith(
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
                                      size: 16,
                                      color: AppColors.textHint,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // ── Latest note ────────────────────────────────────
                        if (lead.latestNote != null) ...[
                          const SizedBox(height: 7),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.sticky_note_2_outlined,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  lead.latestNote!,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ── Reminder ───────────────────────────────────────
                        if (lead.reminderAt != null) ...[
                          const SizedBox(height: 6),
                          _ReminderChip(lead: lead),
                        ],

                        const SizedBox(height: 10),

                        // ── Bottom action row ──────────────────────────────
                        Row(
                          children: [
                            // Call + WhatsApp icon buttons
                            if (lead.clientPhone != null) ...[
                              _CardIconBtn(
                                iconWidget: const Icon(Icons.phone_rounded, size: 16, color: AppColors.info),
                                color: AppColors.info,
                                onTap: () => _call(lead.clientPhone!),
                              ),
                              const SizedBox(width: 8),
                              _CardIconBtn(
                                iconWidget: const WhatsAppLogo(size: 16),
                                color: const Color(0xFF25D366),
                                onTap: () => _whatsApp(lead.clientPhone!),
                              ),
                              const SizedBox(width: 8),
                            ],

                            const Spacer(),

                            // Advance stage
                            if (nextStage != null && onStageAdvance != null)
                              GestureDetector(
                                onTap: onStageAdvance,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: nextStage.color
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: nextStage.color
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 11,
                                        color: nextStage.color,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        nextStage.label,
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: nextStage.color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
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
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CardIconBtn extends StatelessWidget {
  const _CardIconBtn({
    required this.iconWidget,
    required this.color,
    required this.onTap,
  });

  final Widget iconWidget;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Center(child: iconWidget),
      ),
    );
  }
}

class _ListingIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Icon(
        Icons.home_work_outlined,
        color: AppColors.gold,
        size: 20,
      ),
    );
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
      if (ago.inHours < 24) return 'Overdue ${ago.inHours}h ago';
      return 'Overdue ${ago.inDays}d ago';
    }
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
        Icon(Icons.alarm_rounded, size: 11, color: color),
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
          const SizedBox(width: 5),
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

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});
  final int score;

  Color get _color {
    if (score >= 85) return const Color(0xFFE53935);
    if (score >= 65) return AppColors.warning;
    if (score >= 40) return AppColors.gold;
    if (score >= 20) return AppColors.info;
    return AppColors.textSecondary;
  }

  String get _label => scoreBandLabel(score);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

