import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/providers/navigation_overrides.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/crm/presentation/widgets/add_lead_sheet.dart';
import 'package:cpapp/features/crm/presentation/widgets/lead_card.dart';
import 'package:cpapp/features/crm/presentation/widgets/pipeline_stats_bar.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/services/org_permission_service.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_members_screen.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_screen.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_teams_screen.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

class CrmScreen extends ConsumerStatefulWidget {
  const CrmScreen({super.key});

  @override
  ConsumerState<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends ConsumerState<CrmScreen> {
  // Local override so the team-setup gate dismisses immediately after the
  // Firestore write, without waiting for authStateChangesProvider to re-fetch.
  bool _localTeamSetupDone = false;

  void _showOrgPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OrgPanelSheet(),
    );
  }

  void _openAddLead(BuildContext context) => _showAddLeadSheet(context);

  void _showAddLeadSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddLeadSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    // Org members (invited or returning) bypass both setup gates — their admin
    // already configured the CRM. We check three sources in order of reliability:
    //   1. user.orgId — durable Firestore value (available after stream re-emits)
    //   2. currentOrgIdProvider — set synchronously in _applyInviteData
    //   3. pendingOrgInviteProvider — set by router during auth flow
    // This avoids the race window where authStateChanges hasn't re-emitted yet.
    final sessionOrgId = ref.watch(currentOrgIdProvider);
    final hasPendingInvite = ref.watch(pendingOrgInviteProvider) != null;
    final crmSetupDone = ref.watch(crmSetupDoneProvider);
    // Invited members have orgId from an admin invite and accountType='individual'.
    // Org admins (isOrganisation=true) self-created their org and must subscribe.
    final isInvitedMember = user != null &&
        !user.isOrganisation &&
        (user.orgId != null || sessionOrgId != null || hasPendingInvite);

    // ── Setup gate: redirect to subscription if not subscribed ──
    debugPrint('[CRM-SCREEN] user=${user?.uid} isSeller=${user?.isSeller} '
        'hasConfirmedAccountType=${user?.hasConfirmedAccountType} '
        'isOrganisation=${user?.isOrganisation} '
        'isInvitedMember=$isInvitedMember crmSetupDone=$crmSetupDone');
    if (user != null && !user.hasConfirmedAccountType && !isInvitedMember && !crmSetupDone) {
      debugPrint('[CRM-SCREEN] Gate triggered — redirecting to subscription');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.subscriptionPlan);
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    // ── Team setup gate: org admins must set up team before Add Lead ─────────
    if (user != null && user.isOrganisation && !user.hasSetupTeam && !_localTeamSetupDone && !isInvitedMember && !crmSetupDone) {
      return _TeamSetupGateway(
        isDark: isDark,
        onSetupDone: () {
          if (mounted) setState(() => _localTeamSetupDone = true);
        },
      );
    }

    final crmState = ref.watch(crmProvider);
    final urgentCount = ref.watch(urgentReminderCountProvider);
    final totalReminderCount = ref.watch(
      reminderLeadsProvider.select((leads) => leads.length),
    );
    final orgId = ref.watch(currentOrgIdProvider);
    final hasOrg = orgId != null || (user?.orgId != null);

    ref.listen<CrmState>(crmProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(crmProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.crmTitle,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (crmState.leads.isNotEmpty)
              Text(
                '${crmState.activeCount} active · ${crmState.leads.length} total',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          _AppBarAction(
            icon: Icons.person_add_rounded,
            label: 'Add Lead',
            onPressed: () => _openAddLead(context),
          ),
          if (hasOrg && user != null && user.isOrganisation) ...[
            const SizedBox(width: 4),
            _AppBarAction(
              icon: Icons.business_rounded,
              label: 'Manage Team',
              onPressed: () => _showOrgPanel(context),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(crmProvider.notifier).refresh(),
        color: AppColors.gold,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // Trigger paginated fetch when user nears the bottom (200px buffer).
            // Filter is client-side, so paginate against the unfiltered list.
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                !crmState.isLoadingMore &&
                crmState.hasMore &&
                crmState.leads.isNotEmpty) {
              ref.read(crmProvider.notifier).loadOlder();
            }
            return false;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (crmState.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LoadingBody(),
                )
              else ...[
                // ── Reminder banner ──────────────────────────────────────────
                if (totalReminderCount > 0)
                  SliverToBoxAdapter(
                    child: _ReminderBanner(
                      urgentCount: urgentCount,
                      totalCount: totalReminderCount,
                      onTap: () => context.push(Routes.reminders),
                      isDark: isDark,
                    ),
                  ),

                // ── Stats bar ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: crmState.leads.isEmpty
                      ? const SizedBox.shrink()
                      : PipelineStatsBar(crmState: crmState),
                ),

                // ── Stage filter tabs ────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StageTabs(
                    selected: crmState.stageFilter,
                    visitedFilterActive: crmState.visitedFilter,
                    visitedCount: crmState.visitedCount,
                    counts: {
                      for (final s in LeadStage.values)
                        s: crmState.countForStage(s),
                    },
                    total: crmState.leads.length,
                    onSelect: (stage) =>
                        ref.read(crmProvider.notifier).setFilter(stage),
                    onVisitedTap: () => ref
                        .read(crmProvider.notifier)
                        .setVisitedFilter(!crmState.visitedFilter),
                    isDark: isDark,
                  ),
                ),

                // ── Lead list ────────────────────────────────────────────────
                if (crmState.filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      stageFilter: crmState.stageFilter,
                      visitedFilter: crmState.visitedFilter,
                      onAddLead: () => _openAddLead(context),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final lead = crmState.filtered[i];
                        return LeadCard(
                          lead: lead,
                          onTap: () => context.push(_leadDetailPath(lead.id)),
                          onStageAdvance: lead.stage.nextStage != null
                              ? () => ref
                                  .read(crmProvider.notifier)
                                  .updateStage(lead.id, lead.stage.nextStage!)
                              : null,
                        );
                      },
                      childCount: crmState.filtered.length,
                    ),
                  ),

                // ── Pagination footer ────────────────────────────────────────
                if (crmState.isLoadingMore)
                  const SliverToBoxAdapter(child: _LoadingMoreFooter()),

                const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _leadDetailPath(String id) =>
      Routes.leadDetail.replaceFirst(':leadId', id);
}


class _GatewayFeature extends StatelessWidget {
  const _GatewayFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(icon, color: AppColors.gold, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Team setup gate (org sellers must invite members before Add Lead) ─────────

class _TeamSetupGateway extends ConsumerWidget {
  const _TeamSetupGateway({required this.isDark, required this.onSetupDone});
  final bool isDark;
  final VoidCallback onSetupDone;

  Future<void> _setupTeam(BuildContext context, WidgetRef ref) async {
    await ref.read(profileSetupProvider.notifier).saveTeamSetupDone();
    onSetupDone();
    if (context.mounted) context.push(Routes.organisation);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: AppColors.gold,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Set Up Your Team',
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'re on the Team plan. Add your team members to collaborate on leads and close deals together.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 36),
                const _GatewayFeature(
                  icon: Icons.person_add_outlined,
                  title: 'Invite Team Members',
                  subtitle:
                      'Add brokers from your organisation with role-based access.',
                ),
                const SizedBox(height: 16),
                const _GatewayFeature(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Assign Leads',
                  subtitle:
                      'Distribute leads across your team and track who handles what.',
                ),
                const SizedBox(height: 16),
                const _GatewayFeature(
                  icon: Icons.bar_chart_rounded,
                  title: 'Team Performance',
                  subtitle:
                      'Monitor each member\'s pipeline, conversions, and revenue.',
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _setupTeam(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Set Up Team',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.navyDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stage filter tabs (persistent header) ─────────────────────────────────────

class _StageTabs extends SliverPersistentHeaderDelegate {
  const _StageTabs({
    required this.selected,
    required this.visitedFilterActive,
    required this.visitedCount,
    required this.counts,
    required this.total,
    required this.onSelect,
    required this.onVisitedTap,
    required this.isDark,
  });

  final LeadStage? selected;
  final bool visitedFilterActive;
  final int visitedCount;
  final Map<LeadStage, int> counts;
  final int total;
  final ValueChanged<LeadStage?> onSelect;
  final VoidCallback onVisitedTap;
  final bool isDark;

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyDark : AppColors.offWhite,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        children: [
          _Tab(
            label: l.allDeals,
            count: total,
            isSelected: selected == null && !visitedFilterActive,
            color: AppColors.gold,
            onTap: () => onSelect(null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'Visited',
            count: visitedCount,
            isSelected: visitedFilterActive,
            color: AppColors.gold,
            onTap: onVisitedTap,
            isDark: isDark,
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(width: 8),
          ...LeadStage.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Tab(
                label: s.label,
                count: counts[s] ?? 0,
                isSelected: selected == s,
                color: s.color,
                onTap: () => onSelect(s),
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StageTabs old) =>
      old.selected != selected ||
      old.visitedFilterActive != visitedFilterActive ||
      old.visitedCount != visitedCount ||
      old.total != total ||
      old.counts.entries.any((e) => counts[e.key] != e.value);
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
    this.icon,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 12,
                  color: isSelected ? color : AppColors.textSecondary,),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? color : AppColors.textHint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.stageFilter,
    required this.visitedFilter,
    required this.onAddLead,
  });

  final LeadStage? stageFilter;
  final bool visitedFilter;
  final VoidCallback onAddLead;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isFiltered = stageFilter != null || visitedFilter;
    final title = visitedFilter
        ? 'No visited leads'
        : stageFilter != null
            ? 'No ${stageFilter!.label} leads'
            : l.noLeads;
    final subtitle = visitedFilter
        ? 'Leads with at least one site visit will appear here.'
        : isFiltered
            ? l.tryDifferentFilter
            : l.addFirstLeadHint;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFiltered ? '🔍' : '📋',
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onAddLead,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    l.addFirstLead,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.navyDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.gold),
    );
  }
}

class _LoadingMoreFooter extends StatelessWidget {
  const _LoadingMoreFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: AppColors.gold,
            strokeWidth: 2.4,
          ),
        ),
      ),
    );
  }
}

// ── Reminder banner ───────────────────────────────────────────────────────────

class _ReminderBanner extends StatelessWidget {
  const _ReminderBanner({
    required this.urgentCount,
    required this.totalCount,
    required this.onTap,
    required this.isDark,
  });

  final int urgentCount;
  final int totalCount;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isUrgent = urgentCount > 0;
    final accent = isUrgent ? AppColors.error : AppColors.gold;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.55 : 0.65),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUrgent ? Icons.alarm_rounded : Icons.alarm_outlined,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).reminders,
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUrgent
                          ? '$urgentCount urgent · $totalCount total'
                          : totalCount > 0
                              ? '$totalCount reminder${totalCount == 1 ? '' : 's'} set'
                              : 'No reminders set',
                      style: AppTypography.labelSmall.copyWith(
                        color: isUrgent
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontWeight:
                            isUrgent ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (urgentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$urgentCount',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Labelled AppBar action ────────────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.gold, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Organisation panel sheet ───────────────────────────────────────────────────

class _OrgPanelSheet extends ConsumerWidget {
  const _OrgPanelSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateChangesProvider).valueOrNull;
    final org = ref.watch(watchCurrentOrgProvider).valueOrNull;
    final member = ref.watch(currentOrgMemberProvider).valueOrNull;

    if (org == null) return const SizedBox.shrink();

    final isAdmin = org.adminUid == user?.uid;
    final role = member?.role ?? (isAdmin ? OrgRole.admin : OrgRole.view);
    final callerMemberId = member?.id ?? (user != null ? '${user.uid}_${org.id}' : '');
    final canInvite = OrgPermissionService.canInviteRole(role, OrgRole.agent);
    final initial = org.orgName.isNotEmpty ? org.orgName[0].toUpperCase() : 'O';

    void openScreen(Widget screen) {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Org header card ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navyDark, AppColors.navyMid],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                      child: Text(
                        initial,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            org.orgName,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${org.memberCount} member${org.memberCount == 1 ? '' : 's'} · #${org.orgCode}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        role.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (canInvite) ...[
                    _OrgPanelTile(
                      icon: Icons.person_add_outlined,
                      title: 'Invite Member',
                      subtitle: 'Add a broker to ${org.orgName}',
                      accentColor: AppColors.gold,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).pop();
                        showOrgInviteSheet(
                          context,
                          ref,
                          orgId: org.id,
                          orgName: org.orgName,
                          callerMemberId: callerMemberId,
                          callerRole: role,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  _OrgPanelTile(
                    icon: Icons.groups_outlined,
                    title: 'Teams',
                    subtitle: 'Manage teams within ${org.orgName}',
                    accentColor: AppColors.navyMid,
                    isDark: isDark,
                    onTap: () => openScreen(const OrgTeamsScreen()),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 10),
                    _OrgPanelTile(
                      icon: Icons.tune_outlined,
                      title: 'Feed & Lead Settings',
                      subtitle: 'Control visibility and sharing',
                      accentColor: AppColors.gold,
                      isDark: isDark,
                      onTap: () => openScreen(const OrgScreen()),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OrgPanelTile extends StatelessWidget {
  const _OrgPanelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.offWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
