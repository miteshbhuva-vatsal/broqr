import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/providers/navigation_overrides.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';

/// Persistent shell scaffold with persona-aware bottom navigation.
///
/// SELLER tabs: Feed | CRM | Post(+) | Ask | Realtors  (5 items, unchanged)
/// BUYER  tabs: Home | News | Realtors                 (3 items, no CRM/post)
///
/// Branch mapping (StatefulShellRoute.indexedStack):
///   0 = Feed  |  1 = CRM  |  2 = Ask (relabelled News for buyers)  |  3 = Realtors
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // ── Seller tabs (5 visual items; index 2 = centre + button, no branch) ──
  static List<_TabItem> _sellerTabs(AppLocalizations l) => [
    _TabItem(icon: Icons.home_outlined,       activeIcon: Icons.home,         label: l.navFeed,     path: Routes.feed),
    _TabItem(icon: Icons.people_alt_outlined, activeIcon: Icons.people_alt,   label: l.navCrm,      path: Routes.crm),
    _TabItem(icon: Icons.add_circle_outline,  activeIcon: Icons.add_circle,   label: l.navPost,     path: Routes.addListing),
    _TabItem(icon: Icons.forum_outlined,      activeIcon: Icons.forum,        label: l.navAsk,      path: Routes.ask),
    _TabItem(icon: Icons.people_outline,      activeIcon: Icons.people,       label: l.navRealtors, path: Routes.realtors),
  ];

  // ── Buyer tabs (4 visual items; maps branches 0, 1(unused), 2, 3) ────────
  // Branch mapping: Home→0, News→2, Ask→2(reuse), Realtors→3
  // We use branches [0, 2, 2, 3] — News and Ask both hit branch 2
  static List<_TabItem> _buyerTabs(AppLocalizations l) => [
    const _TabItem(icon: Icons.home_outlined,       activeIcon: Icons.home,      label: 'Home',     path: Routes.feed),
    const _TabItem(icon: Icons.newspaper_outlined,  activeIcon: Icons.newspaper, label: 'News',     path: Routes.ask),
    _TabItem(icon: Icons.forum_outlined,            activeIcon: Icons.forum,     label: l.navAsk,   path: Routes.ask),
    const _TabItem(icon: Icons.people_outline,      activeIcon: Icons.people,    label: 'Realtors', path: Routes.realtors),
  ];

  // Branch index for the current visual tab (seller layout).
  int _sellerBranchIndex(int navIndex) => navIndex > 2 ? navIndex - 1 : navIndex;

  // Seller: visual nav index from active branch index.
  int _sellerNavIndex(int branchIndex) => branchIndex >= 2 ? branchIndex + 1 : branchIndex;

  // Buyer branch indices matching buyerTabs positions [0, 2, 2, 3].
  static const _buyerBranches = [0, 2, 2, 3];

  // Buyer: visual nav index from active branch index.
  // Branch 2 maps to the first matching tab (News, index 1).
  int _buyerNavIndex(int branchIndex) {
    final i = _buyerBranches.indexOf(branchIndex);
    return i < 0 ? 0 : i;
  }

  void _onSellerNavTap(BuildContext context, WidgetRef ref, int navIndex) {
    if (navIndex == 2) {
      HapticFeedback.lightImpact();
      context.push(Routes.addListing);
      return;
    }
    HapticFeedback.selectionClick();
    // CRM tab — gate unsubscribed sellers to the subscription flow.
    // goBranch() bypasses GoRouter redirect, so we must check here.
    if (navIndex == 1) {
      final user          = ref.read(authStateChangesProvider).valueOrNull;
      final crmSetupDone  = ref.read(crmSetupDoneProvider);
      final sessionOrgId  = ref.read(currentOrgIdProvider);
      final pendingInvite = ref.read(pendingOrgInviteProvider) != null;
      // An invited member has orgId set by an admin and accountType='individual'.
      // An org admin created their own org during profile setup (isOrganisation=true)
      // — they must still complete the subscription flow.
      final isInvitedMember = user != null &&
          !user.isOrganisation &&
          (user.orgId != null || sessionOrgId != null || pendingInvite);
      debugPrint('[CRM-GATE] persona=${user?.userPersona} '
          'hasConfirmedAccountType=${user?.hasConfirmedAccountType} '
          'isOrganisation=${user?.isOrganisation} '
          'isInvitedMember=$isInvitedMember crmSetupDone=$crmSetupDone '
          'orgId=${user?.orgId}');
      if (user != null &&
          !user.hasConfirmedAccountType &&
          !isInvitedMember &&
          !crmSetupDone) {
        debugPrint('[CRM-GATE] Blocked — redirecting to subscription');
        context.push(Routes.subscriptionPlan);
        return;
      }
      debugPrint('[CRM-GATE] Allowed — proceeding to CRM branch');
    }
    final branch = _sellerBranchIndex(navIndex);
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  void _onBuyerNavTap(BuildContext context, int navIndex) {
    HapticFeedback.selectionClick();
    final branch = _buyerBranches[navIndex];
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final urgent   = ref.watch(urgentReminderCountProvider);
    final l        = AppLocalizations.of(context);
    final user     = ref.watch(authStateChangesProvider).valueOrNull;
    final isBuyer  = user?.isBuyer ?? false;

    final branchIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.navyMid : AppColors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: isBuyer
                ? _buildBuyerNav(context, l, isDark, branchIndex)
                : _buildSellerNav(context, ref, l, isDark, branchIndex, urgent),
          ),
        ),
      ),
    );
  }

  // ── Buyer navigation (3 tabs, no + button) ────────────────────────────────

  Widget _buildBuyerNav(
    BuildContext context,
    AppLocalizations l,
    bool isDark,
    int branchIndex,
  ) {
    final tabs    = _buyerTabs(l);
    final current = _buyerNavIndex(branchIndex);

    return Row(
      children: List.generate(tabs.length, (i) {
        final tab        = tabs[i];
        final isSelected = i == current;
        return Expanded(
          child: _NavItem(
            icon: isSelected ? tab.activeIcon : tab.icon,
            label: tab.label,
            isSelected: isSelected,
            onTap: () => _onBuyerNavTap(context, i),
          ),
        );
      }),
    );
  }

  // ── Seller navigation (5 tabs with centre + button) ───────────────────────

  Widget _buildSellerNav(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    bool isDark,
    int branchIndex,
    int urgent,
  ) {
    final tabs    = _sellerTabs(l);
    final current = _sellerNavIndex(branchIndex);

    return Row(
      children: List.generate(tabs.length, (i) {
        final tab        = tabs[i];
        final isSelected = i == current;

        if (i == 2) {
          return _PostButton(onTap: () => _onSellerNavTap(context, ref, 2));
        }

        if (i == 1) {
          return Expanded(
            child: _NavItem(
              icon: isSelected ? tab.activeIcon : tab.icon,
              label: tab.label,
              isSelected: isSelected,
              badge: urgent > 0 ? urgent : null,
              badgeColor: AppColors.error,
              onTap: () => _onSellerNavTap(context, ref, i),
            ),
          );
        }

        return Expanded(
          child: _NavItem(
            icon: isSelected ? tab.activeIcon : tab.icon,
            label: tab.label,
            isSelected: isSelected,
            onTap: () => _onSellerNavTap(context, ref, i),
          ),
        );
      }),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
  final IconData icon;
  final IconData activeIcon;
  final String   label;
  final String   path;
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.badgeColor = AppColors.gold,
  });

  final IconData     icon;
  final String       label;
  final bool         isSelected;
  final VoidCallback onTap;
  final int?         badge;
  final Color        badgeColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = isSelected
        ? AppColors.gold
        : (isDark ? AppColors.textOnDarkSecondary : AppColors.navyDark);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.18 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: Icon(icon, color: color, size: 24),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge! > 9 ? '9+' : '$badge',
                      style: TextStyle(
                        color: badgeColor == AppColors.error
                            ? AppColors.white
                            : AppColors.navyDark,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Centre post button (seller only) ─────────────────────────────────────────

class _PostButton extends StatelessWidget {
  const _PostButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add, color: AppColors.navyDark, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
