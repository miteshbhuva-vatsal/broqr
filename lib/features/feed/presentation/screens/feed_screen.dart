import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/l10n/locale_provider.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/features/feed/presentation/widgets/category_filter_bar.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/feed/presentation/widgets/city_selection_sheet.dart';
import 'package:cpapp/features/feed/presentation/widgets/feed_card.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _cityPromptShown = false;
  bool _searchVisible = false;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCityPrompt());
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchCtrl.clear();
      ref.read(feedProvider.notifier).setSearchQuery('');
    }
  }

  Future<void> _checkCityPrompt() async {
    await ref.read(cityPreferenceProvider.notifier).initializationFuture;
    if (!mounted) return;
    final city = ref.read(cityPreferenceProvider);
    if (city == null && !_cityPromptShown) {
      _cityPromptShown = true;
      _showCitySelectionSheet();
    }
  }

  void _showCitySelectionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => const CitySelectionSheet(),
    );
  }

  void _openCityPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CitySelectionSheet(),
    );
  }

  void _showLanguagePicker() {
    final current = ref.read(localeProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguagePickerSheet(current: current),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedFilterSheet(
        feedState: ref.read(feedProvider),
        onApply: ({category, propertyType, clearCategory, clearPropertyType}) {
          ref.read(feedProvider.notifier).applyFilters(
                category: category,
                propertyType: propertyType,
                clearCategory: clearCategory ?? false,
                clearPropertyType: clearPropertyType ?? false,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Granular selects — the header only rebuilds for fields it uses.
    // Like-toggles and view-tracking updates do NOT rebuild the header.
    final city            = ref.watch(cityPreferenceProvider);
    final unread          = ref.watch(notificationsProvider.select((s) => s.unreadCount));
    final activeFilters   = ref.watch(feedProvider.select((s) => s.activeFilterCount));
    final mode            = ref.watch(feedProvider.select((s) => s.mode));
    final categoryFilter  = ref.watch(feedProvider.select((s) => s.categoryFilter));
    final orgRestricted   = ref.watch(orgFeedRestrictionProvider) != null;
    final isBuyer         = ref.watch(authStateChangesProvider.select((s) => s.valueOrNull?.isBuyer ?? false));
    final iconColor       = isDark ? AppColors.textOnDarkSecondary : AppColors.navyDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.surfaceLight,
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollCtrl,
          cacheExtent: 600,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverAppBar(
              pinned: false,
              floating: false,
              snap: false,
              backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DigiProp',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.navyDark,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _openCityPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (city != null && city.isNotEmpty)
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : (isDark ? AppColors.surfaceDark : AppColors.offWhite),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (city != null && city.isNotEmpty)
                              ? AppColors.gold
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: (city != null && city.isNotEmpty)
                                ? AppColors.gold
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            (city != null && city.isNotEmpty)
                                ? city
                                : AppLocalizations.of(context).allCities,
                            style: AppTypography.labelSmall.copyWith(
                              color: (city != null && city.isNotEmpty)
                                  ? AppColors.gold
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 16,
                            color: (city != null && city.isNotEmpty)
                                ? AppColors.gold
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showLanguagePicker,
                    child: _LangIcon(color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => context.push(Routes.profile),
                    child: Icon(Icons.person_rounded, size: 22, color: iconColor),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(
                  orgRestricted
                      ? (_searchVisible ? 96 : 48)
                      : (_searchVisible ? 148 : 100),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.navyDark : AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_searchVisible)
                        _InlineSearchBar(
                          controller: _searchCtrl,
                          onChanged: (v) =>
                              ref.read(feedProvider.notifier).setSearchQuery(v),
                        ),
                      _ModeBar(
                        mode: mode,
                        onSelect: ref.read(feedProvider.notifier).setFeedMode,
                        isDark: isDark,
                        activeFilterCount: activeFilters,
                        unreadCount: unread,
                        onFilter: _openFilterSheet,
                        onAlerts: () => context.push(Routes.notifications),
                        searchVisible: _searchVisible,
                        onSearchToggle: _toggleSearch,
                        orgRestricted: orgRestricted,
                        isBuyer: isBuyer,
                      ),
                      if (!orgRestricted)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CategoryFilterBar(
                            selected: categoryFilter,
                            onSelect: (cat) => ref
                                .read(feedProvider.notifier)
                                .applyFilters(
                                  category: cat,
                                  clearCategory: cat == null,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Body: isolated ConsumerWidget — only it rebuilds on feed changes
            const _FeedBodySliver(),
          ],
        ),
      ),
    );
  }

}

// ── Feed body sliver — isolated ConsumerWidget so only it rebuilds on feed data changes ──

class _FeedBodySliver extends ConsumerWidget {
  const _FeedBodySliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(feedProvider.select((s) => s.mode));

    if (mode == FeedMode.inquired) {
      return _buildInquiredSliver(context, ref);
    }

    final feedState = ref.watch(feedProvider);

    if (feedState.isLoading && feedState.listings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          children: List.generate(4, (_) => const _ShimmerCard()),
        ),
      );
    }

    if (feedState.error != null && feedState.listings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          message: feedState.error!,
          onRetry: () => ref.read(feedProvider.notifier).refresh(),
        ),
      );
    }

    if (!feedState.isLoading && feedState.listings.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyState(
          mode: feedState.mode,
          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        ),
      );
    }

    final visible = feedState.visibleListings;
    final searching = feedState.searchQuery.trim().isNotEmpty;
    if (searching && visible.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _NoSearchResults(query: feedState.searchQuery),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => RepaintBoundary(
                child: FeedCard(
                  key: ValueKey(visible[index].id),
                  listing: visible[index],
                ),
              ),
              childCount: visible.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildFooter(context, feedState, searching),
        ),
      ],
    );
  }

  Widget _buildInquiredSliver(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inquiredListingsProvider);
    return async.when(
      loading: () => SliverFillRemaining(
        hasScrollBody: false,
        child: Column(
          children: List.generate(4, (_) => const _ShimmerCard()),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(inquiredListingsProvider),
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: _InquiredEmptyState(),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => RepaintBoundary(
                child: FeedCard(
                  key: ValueKey(listings[index].id),
                  listing: listings[index],
                ),
              ),
              childCount: listings.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, FeedState feedState, bool searching) {
    if (feedState.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    }
    final visible = feedState.visibleListings;
    if (!feedState.hasMore && visible.isNotEmpty && !searching) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            AppLocalizations.of(context).allCaughtUp,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

// ── Inline search bar (shown when search icon is toggled on) ──────────────────

class _InlineSearchBar extends StatelessWidget {
  const _InlineSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.white : AppColors.navyDark,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  hintText: 'Search listings, brokers, locations…',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textHint,
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              )
            else
              const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// ── Feed mode bar ─────────────────────────────────────────────────────────────

class _ModeBar extends StatelessWidget {
  const _ModeBar({
    required this.mode,
    required this.onSelect,
    required this.isDark,
    required this.activeFilterCount,
    required this.unreadCount,
    required this.onFilter,
    required this.onAlerts,
    required this.searchVisible,
    required this.onSearchToggle,
    this.orgRestricted = false,
    this.isBuyer = false,
  });

  final FeedMode mode;
  final ValueChanged<FeedMode> onSelect;
  final bool isDark;
  final int activeFilterCount;
  final int unreadCount;
  final VoidCallback onFilter;
  final VoidCallback onAlerts;
  final bool searchVisible;
  final VoidCallback onSearchToggle;
  final bool orgRestricted;
  final bool isBuyer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (!orgRestricted)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                child: Row(
                  children: [
                    _ModeChip(
                      label: AppLocalizations.of(context).allDeals,
                      selected: mode == FeedMode.all,
                      onTap: () => onSelect(FeedMode.all),
                      isDark: isDark,
                    ),
                    if (!isBuyer) ...[
                      const SizedBox(width: 8),
                      _ModeChip(
                        label: AppLocalizations.of(context).myListingsDeals,
                        selected: mode == FeedMode.mine,
                        onTap: () => onSelect(FeedMode.mine),
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(width: 8),
                    _ModeChip(
                      label: 'Inquired',
                      selected: mode == FeedMode.inquired,
                      onTap: () => onSelect(FeedMode.inquired),
                      isDark: isDark,
                      accentColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          Container(
            height: 22,
            width: 1,
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
          const SizedBox(width: 4),
          _BarIconButton(
            icon: Icons.search_rounded,
            badge: false,
            badgeColor: AppColors.gold,
            onTap: onSearchToggle,
            isDark: isDark,
            active: searchVisible,
          ),
          _BarIconButton(
            icon: Icons.tune_rounded,
            badge: activeFilterCount > 0,
            badgeColor: AppColors.gold,
            onTap: onFilter,
            isDark: isDark,
          ),
          _BarIconButton(
            icon: Icons.notifications_outlined,
            badge: unreadCount > 0,
            badgeColor: AppColors.error,
            onTap: onAlerts,
            isDark: isDark,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.badge,
    this.badgeColor = AppColors.gold,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  final bool badge;
  final Color badgeColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 20,
              color: active
                  ? AppColors.gold
                  : (isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.navyDark),
            ),
            if (badge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.gold;
    final textColor = accentColor != null && selected
        ? accentColor!
        : (selected ? AppColors.navyDark : null);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: accentColor != null ? 0.12 : 1.0)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: textColor ??
                (isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}


class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.textHint,
          ),
          const SizedBox(height: 14),
          Text(
            'No matches for "$query"',
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall.copyWith(
              color: isDark ? AppColors.white : AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different keyword, scroll to load more listings, or clear the search.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inquired empty state ──────────────────────────────────────────────────────

class _InquiredEmptyState extends StatelessWidget {
  const _InquiredEmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_unread_rounded,
              size: 56,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No inquiries yet',
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Listings you contact will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────


class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final base = isDark ? AppColors.surfaceDark : AppColors.shimmerBase;
        final hi = isDark ? AppColors.navyLight : AppColors.shimmerHighlight;
        final color = Color.lerp(base, hi, _anim.value)!;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Box(width: 120, height: 10, color: color),
                    const SizedBox(height: 8),
                    _Box(width: double.infinity, height: 10, color: color),
                    const SizedBox(height: 6),
                    _Box(width: 200, height: 10, color: color),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.height, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: AppColors.textHint,),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).couldNotLoadFeed,
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
              label: Text(
                AppLocalizations.of(context).tryAgain,
                style:
                    AppTypography.labelMedium.copyWith(color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.mode, required this.onRefresh});

  final FeedMode mode;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (emoji, title, sub) = switch (mode) {
      FeedMode.mine => (
          '🏗️',
          l.noListingsPosted,
          l.postFirstDeal,
        ),
      FeedMode.all || FeedMode.inquired => (
          '🏠',
          l.noDealsYet,
          l.beFirstToPost,
        ),
    };

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.gold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: AppTypography.titleSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sub,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Language icon: "क" + "A" overlapping ────────────────────────────────────

class _LangIcon extends StatelessWidget {
  const _LangIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Devanagari "क" — back layer, full opacity
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              'क',
              style: TextStyle(
                fontSize: 16,
                height: 1,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          // English "A" — front layer, overlapping bottom-right of क
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              color: color.withValues(alpha: 0.0), // transparent backing to pop it forward
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: color,
                  shadows: [
                    Shadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0C1E3C)
                          : Colors.white,
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language picker sheet ─────────────────────────────────────────────────────

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet({required this.current});
  final Locale current;

  static const _langs = [
    (Locale('en'), 'English', 'EN'),
    (Locale('hi'), 'हिन्दी', 'HI'),
    (Locale('gu'), 'ગુજરાતી', 'GU'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).selectLanguage,
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._langs.map((entry) {
            final (loc, name, code) = entry;
            final selected = locale.languageCode == loc.languageCode;
            return GestureDetector(
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(loc);
                Navigator.of(context).pop();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : (isDark ? AppColors.surfaceDark : AppColors.offWhite),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.gold : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.gold
                            : (isDark ? AppColors.navyLight : AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          code,
                          style: AppTypography.labelSmall.copyWith(
                            color: selected
                                ? AppColors.navyDark
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: selected
                            ? (isDark ? AppColors.white : AppColors.navyDark)
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    if (selected)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.gold, size: 20,),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Feed filter sheet ─────────────────────────────────────────────────────────

class _FeedFilterSheet extends StatefulWidget {
  const _FeedFilterSheet({required this.feedState, required this.onApply});

  final FeedState feedState;
  final void Function({
    ListingCategory? category,
    PropertyType? propertyType,
    bool? clearCategory,
    bool? clearPropertyType,
  }) onApply;

  @override
  State<_FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<_FeedFilterSheet> {
  late ListingCategory? _category;
  late PropertyType? _propertyType;

  @override
  void initState() {
    super.initState();
    _category = widget.feedState.categoryFilter;
    _propertyType = widget.feedState.propertyTypeFilter;
  }

  void _apply() {
    widget.onApply(
      category: _category,
      propertyType: _propertyType,
      clearCategory: _category == null,
      clearPropertyType: _propertyType == null,
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _category = null;
      _propertyType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.navyMid : AppColors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context).filterListings,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.white : AppColors.navyDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    AppLocalizations.of(context).reset,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.of(context).dealType.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 2.8,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              children: ListingCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = sel ? null : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withValues(alpha: 0.18)
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.offWhite),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? cat.color : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${cat.emoji} ${cat.localizedLabel(Localizations.localeOf(context).languageCode)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: sel ? cat.color : AppColors.textSecondary,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.of(context).propertyType.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PropertyType.values.map((pt) {
                final sel = _propertyType == pt;
                return GestureDetector(
                  onTap: () => setState(() => _propertyType = sel ? null : pt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.offWhite),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel
                            ? AppColors.gold
                            : (isDark ? AppColors.borderDark : AppColors.border),
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${pt.emoji} ${pt.label}',
                      style: AppTypography.labelSmall.copyWith(
                        color: sel
                            ? AppColors.gold
                            : (isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary),
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context).applyFilters,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
