import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';

/// Persistent shell scaffold with bottom navigation bar.
/// Tabs: Feed | News | Post(+) | Reminders | CRM
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,       activeIcon: Icons.home,            label: 'Feed',      path: Routes.feed),
    _TabItem(icon: Icons.newspaper_outlined,  activeIcon: Icons.newspaper,       label: 'News',      path: Routes.news),
    _TabItem(icon: Icons.add_circle_outline,  activeIcon: Icons.add_circle,      label: 'Post',      path: Routes.addListing),
    _TabItem(icon: Icons.alarm_outlined,      activeIcon: Icons.alarm,           label: 'Reminders', path: Routes.reminders),
    _TabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment,      label: 'CRM',       path: Routes.crm),
  ];

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith(Routes.feed))      return 0;
    if (loc.startsWith(Routes.news))      return 1;
    if (loc.startsWith(Routes.reminders)) return 3;
    if (loc.startsWith(Routes.crm))       return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final current  = _selectedIndex(context);
    final urgent   = ref.watch(urgentReminderCountProvider);

    return Scaffold(
      body: child,
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
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab        = _tabs[i];
                final isSelected = i == current;

                // Index 2 → centre gold "+" post button
                if (i == 2) {
                  return _PostButton(
                    onTap: () => context.push(Routes.addListing),
                  );
                }

                // Index 3 → Reminders with urgent badge
                if (i == 3) {
                  return Expanded(
                    child: _NavItem(
                      icon: isSelected ? tab.activeIcon : tab.icon,
                      label: tab.label,
                      isSelected: isSelected,
                      badge: urgent > 0 ? urgent : null,
                      badgeColor: AppColors.error,
                      onTap: () => context.go(tab.path),
                    ),
                  );
                }

                return Expanded(
                  child: _NavItem(
                    icon: isSelected ? tab.activeIcon : tab.icon,
                    label: tab.label,
                    isSelected: isSelected,
                    onTap: () => context.go(tab.path),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
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
        : (isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, color: color, size: 24),
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

// ── Centre post button ────────────────────────────────────────────────────────

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
