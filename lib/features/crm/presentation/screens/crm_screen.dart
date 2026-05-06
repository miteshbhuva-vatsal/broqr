import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/crm/presentation/widgets/add_lead_sheet.dart';
import 'package:cpapp/features/crm/presentation/widgets/lead_card.dart';
import 'package:cpapp/features/crm/presentation/widgets/pipeline_stats_bar.dart';
import 'package:cpapp/shared/widgets/phone_otp_sheet.dart';

class CrmScreen extends ConsumerWidget {
  const CrmScreen({super.key});

  void _openAddLead(BuildContext context, WidgetRef ref) {
    final isVerified = ref.read(isPhoneVerifiedProvider);
    if (isVerified) {
      _showAddLeadSheet(context);
    } else {
      final user = ref.read(authStateChangesProvider).valueOrNull;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PhoneOtpSheet(
          initialPhone: user?.mobile,
          onVerified: () {
            if (context.mounted) _showAddLeadSheet(context);
          },
        ),
      );
    }
  }

  void _showAddLeadSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddLeadSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final crmState = ref.watch(crmProvider);

    // Show error snack if any
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
        title: Text(
          l.crmTitle,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 26),
            color: AppColors.gold,
            onPressed: () => _openAddLead(context, ref),
            tooltip: l.addLead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(crmProvider.notifier).refresh(),
        color: AppColors.gold,
        child: crmState.isLoading
            ? const _LoadingBody()
            : _PipelineBody(
                crmState: crmState,
                isDark: isDark,
                onAddLead: () => _openAddLead(context, ref),
                onLeadTap: (lead) =>
                    context.push(_leadDetailPath(lead.id)),
                onStageAdvance: (lead) => ref
                    .read(crmProvider.notifier)
                    .updateStage(lead.id, lead.stage.nextStage!),
                onFilterSelect: (stage) =>
                    ref.read(crmProvider.notifier).setFilter(stage),
              ),
      ),
    );
  }

  String _leadDetailPath(String id) =>
      Routes.leadDetail.replaceFirst(':leadId', id);
}

// ── Pipeline body ─────────────────────────────────────────────────────────────

class _PipelineBody extends StatelessWidget {
  const _PipelineBody({
    required this.crmState,
    required this.isDark,
    required this.onAddLead,
    required this.onLeadTap,
    required this.onStageAdvance,
    required this.onFilterSelect,
  });

  final CrmState crmState;
  final bool isDark;
  final VoidCallback onAddLead;
  final ValueChanged<Lead> onLeadTap;
  final ValueChanged<Lead> onStageAdvance;
  final ValueChanged<LeadStage?> onFilterSelect;

  @override
  Widget build(BuildContext context) {
    final leads = crmState.filtered;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Stats bar ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: crmState.leads.isEmpty
              ? const SizedBox.shrink()
              : PipelineStatsBar(crmState: crmState),
        ),

        // ── Stage filter tabs ──────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _StageTabs(
            selected: crmState.stageFilter,
            counts: {
              for (final s in LeadStage.values) s: crmState.countForStage(s),
            },
            total: crmState.leads.length,
            onSelect: onFilterSelect,
            isDark: isDark,
          ),
        ),

        // ── Lead list ──────────────────────────────────────────────────
        if (leads.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              stageFilter: crmState.stageFilter,
              onAddLead: onAddLead,
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final lead = leads[i];
                return LeadCard(
                  lead: lead,
                  onTap: () => onLeadTap(lead),
                  onStageAdvance: lead.stage.nextStage != null
                      ? () => onStageAdvance(lead)
                      : null,
                );
              },
              childCount: leads.length,
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

// ── Stage tabs (persistent header) ───────────────────────────────────────────

class _StageTabs extends SliverPersistentHeaderDelegate {
  const _StageTabs({
    required this.selected,
    required this.counts,
    required this.total,
    required this.onSelect,
    required this.isDark,
  });

  final LeadStage? selected;
  final Map<LeadStage, int> counts;
  final int total;
  final ValueChanged<LeadStage?> onSelect;
  final bool isDark;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final l = AppLocalizations.of(context);
    return Container(
      color: isDark ? AppColors.navyDark : AppColors.offWhite,
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _Tab(
            label: l.allDeals,
            count: total,
            isSelected: selected == null,
            color: AppColors.gold,
            onTap: () => onSelect(null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          ...LeadStage.values.map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Tab(
                  label: s.label,
                  count: counts[s] ?? 0,
                  isSelected: selected == s,
                  color: s.color,
                  onTap: () => onSelect(s),
                  isDark: isDark,
                ),
              ),),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StageTabs old) =>
      old.selected != selected || old.total != total;
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

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
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
  const _EmptyState({required this.stageFilter, required this.onAddLead});

  final LeadStage? stageFilter;
  final VoidCallback onAddLead;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isFiltered = stageFilter != null;
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
              isFiltered
                  ? 'No ${stageFilter!.label} leads'
                  : l.noLeads,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? l.tryDifferentFilter
                  : l.addFirstLeadHint,
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
