import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/locale_provider.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/features/feed/presentation/widgets/city_selection_sheet.dart';
import 'package:cpapp/features/feed/presentation/widgets/feed_card.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _cityPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCityPrompt());
  }

  void _checkCityPrompt() {
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

  void _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 300) {
      ref.read(feedProvider.notifier).loadMore();
    }
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
  Widget build(BuildContext context, ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedState = ref.watch(feedProvider);
    final city = ref.watch(cityPreferenceProvider);
    final unread = ref.watch(
      notificationsProvider.select((s) => s.unreadCount),
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _onScrollNotification(n);
          return false;
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
              elevation: innerBoxIsScrolled ? 1 : 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CPApp',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4,),
                      decoration: BoxDecoration(
                        color: (city != null && city.isNotEmpty)
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.offWhite),
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
                ],
              ),
              actions: [
                // Language switcher
                IconButton(
                  icon: Icon(
                    Icons.translate_rounded,
                    color: isDark ? AppColors.white : AppColors.navyDark,
                    size: 22,
                  ),
                  onPressed: _showLanguagePicker,
                  tooltip: AppLocalizations.of(context).selectLanguage,
                ),
                // Profile
                IconButton(
                  icon: Icon(
                    Icons.person_outline_rounded,
                    color: isDark ? AppColors.white : AppColors.navyDark,
                    size: 24,
                  ),
                  onPressed: () => context.push(Routes.profile),
                  tooltip: 'Profile',
                ),
                // Notifications
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        size: 24,
                      ),
                      onPressed: () => context.push(Routes.notifications),
                      tooltip: 'Notifications',
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unread > 9 ? '9+' : '$unread',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Filter
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: feedState.activeFilterCount > 0
                            ? AppColors.gold
                            : (isDark ? AppColors.white : AppColors.navyDark),
                        size: 24,
                      ),
                      onPressed: _openFilterSheet,
                      tooltip: 'Filters',
                    ),
                    if (feedState.activeFilterCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${feedState.activeFilterCount}',
                              style: const TextStyle(
                                color: AppColors.navyDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _ModeBar(
                  mode: feedState.mode,
                  onSelect: ref.read(feedProvider.notifier).setFeedMode,
                  isDark: isDark,
                ),
              ),
            ),
          ],
          body: _FeedBody(
            feedState: feedState,
            onRefresh: () => ref.read(feedProvider.notifier).refresh(),
          ),
        ),
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
          // Handle
          Center(
            child: Container(
              width: 36, height: 4,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      width: 36, height: 36,
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
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
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

// ── Feed mode bar ─────────────────────────────────────────────────────────────

class _ModeBar extends StatelessWidget {
  const _ModeBar({
    required this.mode,
    required this.onSelect,
    required this.isDark,
  });

  final FeedMode mode;
  final ValueChanged<FeedMode> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          _ModeChip(
            label: AppLocalizations.of(context).allDeals,
            selected: mode == FeedMode.all,
            onTap: () => onSelect(FeedMode.all),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: AppLocalizations.of(context).myNetworkDeals,
            selected: mode == FeedMode.network,
            onTap: () => onSelect(FeedMode.network),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _ModeChip(
            label: AppLocalizations.of(context).myListingsDeals,
            selected: mode == FeedMode.mine,
            onTap: () => onSelect(FeedMode.mine),
            isDark: isDark,
          ),
        ],
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: selected
                ? AppColors.navyDark
                : (isDark
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

// ── Filter bottom sheet ───────────────────────────────────────────────────────

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
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
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
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Deal Type
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
                  onTap: () => setState(
                    () => _category = sel ? null : cat,
                  ),
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
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
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
          // Property Type
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
                  onTap: () => setState(
                    () => _propertyType = sel ? null : pt,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.navyDark.withValues(alpha: 0.1)
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.offWhite),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.navyDark : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${pt.emoji} ${pt.label}',
                      style: AppTypography.labelSmall.copyWith(
                        color: sel
                            ? AppColors.navyDark
                            : AppColors.textSecondary,
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Apply button
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

// ── Feed body ─────────────────────────────────────────────────────────────────

class _FeedBody extends StatelessWidget {
  const _FeedBody({required this.feedState, required this.onRefresh});

  final FeedState feedState;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (feedState.isLoading && feedState.listings.isEmpty) {
      return const _ShimmerList();
    }

    if (feedState.error != null && feedState.listings.isEmpty) {
      return _ErrorState(message: feedState.error!, onRetry: onRefresh);
    }

    if (!feedState.isLoading && feedState.listings.isEmpty) {
      return _EmptyState(
        mode: feedState.mode,
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: feedState.listings.length + 1,
        itemBuilder: (context, index) {
          if (index == feedState.listings.length) {
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
            if (!feedState.hasMore && feedState.listings.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context).allCaughtUp,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }
          return FeedCard(listing: feedState.listings[index]);
        },
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 4,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }
}

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
        final hi =
            isDark ? AppColors.navyLight : AppColors.shimmerHighlight;
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
                    _Box(
                      width: double.infinity,
                      height: 10,
                      color: color,
                    ),
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).couldNotLoadFeed,
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textHint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
              label: Text(
                AppLocalizations.of(context).tryAgain,
                style: AppTypography.labelMedium.copyWith(color: AppColors.gold),
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
      FeedMode.network => (
          '🤝',
          l.noNetworkListings,
          l.connectToBrokerSeeDeals,
        ),
      FeedMode.mine => (
          '🏗️',
          l.noListingsPosted,
          l.postFirstDeal,
        ),
      FeedMode.all => (
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
                  Text(emoji, style: const TextStyle(fontSize: 56),),
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
