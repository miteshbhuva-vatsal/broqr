import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/news/domain/entities/news_article.dart';
import 'package:cpapp/features/news/presentation/providers/news_providers.dart';
import 'package:cpapp/features/news/presentation/widgets/news_card.dart';

// ── Filter categories ──────────────────────────────────────────────────────────

enum _Filter {
  all('All'),
  property('Property'),
  realestate('Real Estate'),
  govt('Govt & RERA'),
  vernacular('हिंदी');

  const _Filter(this.label);
  final String label;
}

bool _matches(NewsArticle a, _Filter f) {
  if (f == _Filter.all) return true;
  final haystack =
      '${a.title} ${a.description ?? ''} ${a.sourceName}'.toLowerCase();
  return switch (f) {
    _Filter.property => haystack.contains('flat') ||
        haystack.contains('apartment') ||
        haystack.contains('villa') ||
        haystack.contains('plot') ||
        haystack.contains('bhk') ||
        haystack.contains('house') ||
        haystack.contains('property'),
    _Filter.realestate => haystack.contains('real estate') ||
        haystack.contains('realty') ||
        haystack.contains('developer') ||
        haystack.contains('builder') ||
        haystack.contains('construction'),
    _Filter.govt => haystack.contains('rera') ||
        haystack.contains('government') ||
        haystack.contains('govt') ||
        haystack.contains('policy') ||
        haystack.contains('regulation') ||
        haystack.contains('notification') ||
        haystack.contains('ministry'),
    _Filter.vernacular => haystack.contains('संपत्ति') ||
        haystack.contains('रियल') ||
        haystack.contains('आवास') ||
        haystack.contains('मकान') ||
        a.sourceName.toLowerCase().contains('ujala') ||
        a.sourceName.toLowerCase().contains('hindi') ||
        a.sourceName.toLowerCase().contains('bhaskar'),
    _Filter.all => true,
  };
}

// ── Screen ────────────────────────────────────────────────────────────────────

class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  _Filter _activeFilter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newsState = ref.watch(newsProvider);
    final city = ref.watch(authStateChangesProvider).valueOrNull?.city;

    final filtered = newsState.articles
        .where((a) => _matches(a, _activeFilter))
        .toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : const Color(0xFFF2F4F7),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _NewsAppBar(city: city, isDark: isDark),
        ],
        body: RefreshIndicator(
          onRefresh: () => ref.read(newsProvider.notifier).refresh(),
          color: AppColors.gold,
          backgroundColor: isDark ? AppColors.navyMid : AppColors.white,
          child: CustomScrollView(
            slivers: [
              // ── Filter chips ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _FilterRow(
                  active: _activeFilter,
                  onSelect: (f) => setState(() => _activeFilter = f),
                  isDark: isDark,
                ),
              ),

              // ── Last updated timestamp ──────────────────────────────────
              if (newsState.lastFetched != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Text(
                      'Updated ${_ago(newsState.lastFetched!)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

              // ── Loading shimmer ─────────────────────────────────────────
              if (newsState.isLoading && newsState.articles.isEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => _ShimmerCard(isDark: isDark),
                    childCount: 5,
                  ),
                )

              // ── Error state ─────────────────────────────────────────────
              else if (newsState.error != null && newsState.articles.isEmpty)
                SliverFillRemaining(
                  child: _ErrorState(
                    onRetry: () => ref.read(newsProvider.notifier).refresh(),
                    isDark: isDark,
                  ),
                )

              // ── Empty after filter ──────────────────────────────────────
              else if (filtered.isEmpty && !newsState.isLoading)
                SliverFillRemaining(
                  child: _EmptyState(
                    filter: _activeFilter,
                    isDark: isDark,
                    onClear: () => setState(() => _activeFilter = _Filter.all),
                  ),
                )

              // ── Article list ─────────────────────────────────────────────
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => NewsCard(article: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── App bar ───────────────────────────────────────────────────────────────────

class _NewsAppBar extends StatelessWidget {
  const _NewsAppBar({required this.city, required this.isDark});
  final String? city;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      expandedHeight: 88,
      backgroundColor: AppColors.navyDark,
      foregroundColor: AppColors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'News',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            if (city != null && city!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.gold,
                      size: 10,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      city!,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips row ──────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.active,
    required this.onSelect,
    required this.isDark,
  });

  final _Filter active;
  final ValueChanged<_Filter> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        children: _Filter.values.map((f) {
          final isActive = f == active;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.gold
                    : (isDark
                        ? AppColors.surfaceDark
                        : AppColors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? AppColors.gold
                      : (isDark ? AppColors.borderDark : AppColors.border),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  color: isActive
                      ? AppColors.navyDark
                      : (isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary),
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Shimmer loading card ──────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.navyMid : AppColors.border;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      height: (MediaQuery.of(context).size.width - 28) * 9 / 16,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filter,
    required this.isDark,
    required this.onClear,
  });
  final _Filter filter;
  final bool isDark;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.newspaper_outlined,
                size: 48, color: AppColors.gold,),
            const SizedBox(height: 16),
            Text(
              'No ${filter.label} news this week',
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different category or pull down to refresh.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: AppColors.gold),
              child: const Text('Show All'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.isDark});
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: isDark
                  ? AppColors.textOnDarkSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load news.\nCheck your connection.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navyDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
