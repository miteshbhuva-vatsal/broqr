import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/services/seed_service.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/chat/presentation/providers/chat_providers.dart';
import 'package:cpapp/features/realtors/presentation/providers/realtors_providers.dart';
import 'package:cpapp/features/realtors/presentation/widgets/realtor_card.dart';

class RealtorsScreen extends ConsumerStatefulWidget {
  const RealtorsScreen({super.key});

  @override
  ConsumerState<RealtorsScreen> createState() => _RealtorsScreenState();
}

class _RealtorsScreenState extends ConsumerState<RealtorsScreen> {
  bool _searchVisible = false;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      ref.read(realtorsProvider.notifier).loadMore();
    }
  }

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchCtrl.clear();
      ref.read(realtorsProvider.notifier).setSearchQuery('');
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        state: ref.read(realtorsProvider),
        onApply: ({city, clearCity, accountType, clearAccountType, category, clearCategory}) {
          ref.read(realtorsProvider.notifier).applyFilters(
                city: city,
                clearCity: clearCity ?? false,
                accountType: accountType,
                clearAccountType: clearAccountType ?? false,
                category: category,
                clearCategory: clearCategory ?? false,
              );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(realtorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authStateChangesProvider).valueOrNull;
    final currentUserId = currentUser?.uid ?? '';
    final unread = ref.watch(totalUnreadProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.offWhite,
      floatingActionButton: kDebugMode
          ? FloatingActionButton.small(
              heroTag: 'realtors-seed-fab',
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
              tooltip: 'Seed broker profiles',
              onPressed: () async {
                try {
                  await SeedService.seedBrokerProfiles();
                  if (context.mounted) {
                    ref.read(realtorsProvider.notifier).refresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('6 dummy brokers seeded'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Seed failed: $e'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              child: const Icon(Icons.science_outlined, size: 18),
            )
          : null,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: isDark ? AppColors.navyMid : AppColors.navyDark,
            foregroundColor: AppColors.white,
            title: Text(
              'Realtors',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    color: AppColors.white,
                    onPressed: () => context.push(Routes.chat),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(_searchVisible ? 96 : 48),
              child: Column(
                children: [
                  _FilterBar(
                    activeFilterCount: state.activeFilterCount,
                    searchVisible: _searchVisible,
                    onSearchToggle: _toggleSearch,
                    onFilter: _openFilterSheet,
                    isDark: isDark,
                  ),
                  if (_searchVisible)
                    _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (q) =>
                          ref.read(realtorsProvider.notifier).setSearchQuery(q),
                      isDark: isDark,
                    ),
                ],
              ),
            ),
          ),

          // ── Active filter chips ────────────────────────────────────
          if (state.activeFilterCount > 0)
            SliverToBoxAdapter(
              child: _ActiveFilters(
                state: state,
                onClear: (key) {
                  ref.read(realtorsProvider.notifier).applyFilters(
                        clearCity: key == 'city',
                        clearAccountType: key == 'accountType',
                        clearCategory: key == 'category',
                      );
                },
              ),
            ),

          // ── Loading first page ─────────────────────────────────────
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )

          // ── Error ──────────────────────────────────────────────────
          else if (state.error != null && state.realtors.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () =>
                          ref.read(realtorsProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )

          // ── Empty ──────────────────────────────────────────────────
          else if (state.visible.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: (isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.textSecondary)
                          .withValues(alpha: .4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.searchQuery.isNotEmpty
                          ? 'No results for "${state.searchQuery}"'
                          : 'No realtors found',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )

          // ── List ──────────────────────────────────────────────────
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final user = state.visible[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: RealtorCard(
                        user: user,
                        currentUserId: currentUserId,
                        onTap: () => context.push(
                          Routes.realtorProfile.replaceFirst(
                            ':realtorId', user.uid,
                          ),
                        ),
                        onChat: () {
                          final ids = [currentUserId, user.uid]..sort();
                          final chatId = ids.join('_');
                          context.push(
                            Routes.chatDetail.replaceFirst(':chatId', chatId),
                            extra: {
                              'otherName': user.name,
                              'otherPhoto': user.photoUrl,
                              'otherUid': user.uid,
                            },
                          );
                        },
                      ),
                    );
                  },
                  childCount: state.visible.length,
                ),
              ),
            ),

            // ── Footer: load-more spinner / end marker ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: state.isLoadingMore
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : !state.hasMore && state.realtors.isNotEmpty
                        ? Center(
                            child: Text(
                              '— ${state.realtors.length} realtors —',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textOnDarkSecondary
                                    : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.activeFilterCount,
    required this.searchVisible,
    required this.onSearchToggle,
    required this.onFilter,
    required this.isDark,
  });

  final int activeFilterCount;
  final bool searchVisible;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilter;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.borderDark : Colors.white24;
    return Container(
      height: 48,
      color: isDark ? AppColors.navyMid : AppColors.navyDark,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Browse all realtors',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .7),
                fontSize: 13,
              ),
            ),
          ),
          Container(width: 1, height: 22, color: border),
          _IconBtn(
            icon: Icons.search_rounded,
            active: searchVisible,
            onTap: onSearchToggle,
          ),
          _IconBtn(
            icon: Icons.tune_rounded,
            badge: activeFilterCount > 0,
            onTap: onFilter,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.gold : Colors.white70,
            ),
            if (badge)
              Positioned(
                top: -3,
                right: -4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
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

// ── Inline search bar ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.isDark,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: isDark ? AppColors.navyMid : AppColors.navyDark,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: AppColors.gold,
        decoration: InputDecoration(
          hintText: 'Search by name, city, company…',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
          filled: true,
          fillColor: Colors.white.withValues(alpha: .1),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Active filter chips row ───────────────────────────────────────────────────

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.state, required this.onClear});
  final RealtorsState state;
  final void Function(String key) onClear;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          if (state.cityFilter != null)
            _ActiveChip(
              label: state.cityFilter!,
              onRemove: () => onClear('city'),
            ),
          if (state.accountTypeFilter != null)
            _ActiveChip(
              label: state.accountTypeFilter == 'organisation'
                  ? 'Organisation'
                  : 'Individual',
              onRemove: () => onClear('accountType'),
            ),
          if (state.categoryFilter != null)
            _ActiveChip(
              label: state.categoryFilter!,
              onRemove: () => onClear('category'),
            ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.gold : AppColors.navyDark;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: textColor),
          ),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

typedef _ApplyFilters = void Function({
  String? city,
  bool? clearCity,
  String? accountType,
  bool? clearAccountType,
  String? category,
  bool? clearCategory,
});

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.state, required this.onApply});
  final RealtorsState state;
  final _ApplyFilters onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _city;
  String? _accountType;
  String? _category;

  static const _cities = [
    'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai',
    'Pune', 'Ahmedabad', 'Kolkata', 'Surat', 'Jaipur',
    'Lucknow', 'Nagpur', 'Indore', 'Thane', 'Bhopal',
  ];

  @override
  void initState() {
    super.initState();
    _city = widget.state.cityFilter;
    _accountType = widget.state.accountTypeFilter;
    _category = widget.state.categoryFilter;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Filter Realtors',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? AppColors.white : AppColors.navyDark,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _city = null;
                      _accountType = null;
                      _category = null;
                    });
                  },
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── City ─────────────────────────────────────────────
                  _FilterSection(
                    label: 'City / Area',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _cities.map((c) {
                        final sel = _city == c;
                        return _ChoiceChip(
                          label: c,
                          selected: sel,
                          onTap: () =>
                              setState(() => _city = sel ? null : c),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Account type ──────────────────────────────────────
                  _FilterSection(
                    label: 'Realtor Type',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChoiceChip(
                          label: 'Individual',
                          selected: _accountType == 'individual',
                          onTap: () => setState(() => _accountType =
                              _accountType == 'individual'
                                  ? null
                                  : 'individual',),
                        ),
                        _ChoiceChip(
                          label: 'Organisation',
                          selected: _accountType == 'organisation',
                          onTap: () => setState(() => _accountType =
                              _accountType == 'organisation'
                                  ? null
                                  : 'organisation',),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Deal category ─────────────────────────────────────
                  _FilterSection(
                    label: 'Deal Category',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ListingCategory.values.map((cat) {
                        final sel = _category == cat.name;
                        return _ChoiceChip(
                          label: '${cat.emoji} ${cat.label}',
                          selected: sel,
                          onTap: () => setState(
                            () => _category = sel ? null : cat.name,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onApply(
                    city: _city,
                    clearCity: _city == null &&
                        widget.state.cityFilter != null,
                    accountType: _accountType,
                    clearAccountType: _accountType == null &&
                        widget.state.accountTypeFilter != null,
                    category: _category,
                    clearCategory: _category == null &&
                        widget.state.categoryFilter != null,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.gold
                : (isDark ? AppColors.textOnDarkSecondary : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
