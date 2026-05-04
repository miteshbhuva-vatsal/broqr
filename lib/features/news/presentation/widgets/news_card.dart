import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/news/domain/entities/news_article.dart';
import 'package:cpapp/features/news/presentation/screens/news_detail_screen.dart';

/// Google-News-style card: full-width image with headline overlay at bottom.
class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.article});

  final NewsArticle article;

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewsDetailScreen(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _timeAgo(article.publishedAt);

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Background image ─────────────────────────────────────
                article.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: article.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 600,
                        placeholder: (_, __) => const _ImagePlaceholder(),
                        errorWidget: (_, __, ___) => const _ImagePlaceholder(),
                      )
                    : const _ImagePlaceholder(),

                // ── Dark gradient from bottom ────────────────────────────
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD000000)],
                      stops: [0.35, 1.0],
                    ),
                  ),
                ),

                // ── Category chip top-left ───────────────────────────────
                Positioned(
                  top: 10,
                  left: 10,
                  child: _CategoryChip(sourceName: article.sourceName),
                ),

                // ── Headline + meta at bottom ────────────────────────────
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        article.title,
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          shadows: [
                            const Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              article.sourceName,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeStr.isNotEmpty)
                            Text(
                              timeStr,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
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

// ── Source / category chip ────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.sourceName});
  final String sourceName;

  String get _label {
    final lower = sourceName.toLowerCase();
    if (lower.contains('rera') || lower.contains('govt') || lower.contains('government')) {
      return 'GOVT';
    }
    if (lower.contains('amarujala') || lower.contains('amar') || lower.contains('hindi')) {
      return 'हिंदी';
    }
    return 'Property';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Image placeholder ─────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF1A2E4A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.home_work_outlined,
              color: AppColors.gold.withValues(alpha: 0.5),
              size: 36,
            ),
            const SizedBox(height: 6),
            Text(
              'Real Estate News',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
