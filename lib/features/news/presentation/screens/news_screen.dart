import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

// ── Provider (package-visible so NewsFeedBody can reuse it) ──────────────────

// ignore: library_private_types_in_public_api
final newsProvider = FutureProvider<List<_NewsItem>>((ref) async {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ),);
  final res = await dio.get<dynamic>('/api/news');
  final data = res.data;
  if (data is! Map) return [];
  final results = data['results'] as List? ?? [];
  return results.map((e) {
    final m = e as Map<String, dynamic>;
    return _NewsItem(
      title: m['title'] as String? ?? '',
      source: m['source']?['name'] as String? ?? '',
      date: m['date'] as String? ?? '',
      imageUrl: m['thumbnail'] as String?,
      link: m['link'] as String? ?? '',
      snippet: m['snippet'] as String? ?? '',
    );
  }).where((n) => n.title.isNotEmpty).toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                const Icon(Icons.newspaper_rounded,
                    color: AppColors.gold, size: 22,),
                const SizedBox(width: 8),
                Text(
                  'Real Estate News',
                  style: AppTypography.titleSmall.copyWith(
                    color: isDark ? AppColors.white : AppColors.navyDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.textSecondary,
                onPressed: () => ref.invalidate(newsProvider),
              ),
            ],
          ),

          // ── Content ──────────────────────────────────────────────────
          newsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
            error: (_, __) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.textSecondary, size: 48,),
                    const SizedBox(height: 12),
                    Text(
                      'Couldn\'t load news',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => ref.invalidate(newsProvider),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
            data: (items) => items.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No news available right now.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _NewsCard(
                          item: items[i],
                          isDark: isDark,
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Embeddable feed body (used by AskScreen News tab) ────────────────────────

class NewsFeedBody extends ConsumerWidget {
  const NewsFeedBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final newsAsync = ref.watch(newsProvider);

    return newsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textSecondary, size: 48,),
            const SizedBox(height: 12),
            Text(
              'Couldn\'t load news',
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(newsProvider),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
      data: (items) => items.isEmpty
          ? Center(
              child: Text(
                'No news available right now.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              itemBuilder: (ctx, i) =>
                  _NewsCard(item: items[i], isDark: isDark),
            ),
    );
  }
}

// ── News card ─────────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.isDark});
  final _NewsItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ─────────────────────────────────────────────
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Image.network(
                item.imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  child: const Icon(Icons.article_outlined,
                      color: AppColors.textSecondary,),
                ),
              ),
            )
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: const Icon(Icons.article_outlined,
                  color: AppColors.textSecondary,),
            ),

          // ── Text content ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.source.isNotEmpty) ...[
                    Text(
                      item.source.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    item.title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.navyDark,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.date,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _NewsItem {
  const _NewsItem({
    required this.title,
    required this.source,
    required this.date,
    required this.link,
    required this.snippet,
    this.imageUrl,
  });

  final String title;
  final String source;
  final String date;
  final String link;
  final String snippet;
  final String? imageUrl;
}
