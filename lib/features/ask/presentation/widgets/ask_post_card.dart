import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:share_plus/share_plus.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/services/deep_link_service.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/ask/domain/entities/ask_post.dart';
import 'package:cpapp/features/ask/presentation/providers/ask_providers.dart';
import 'package:cpapp/features/ask/presentation/widgets/ask_comments_sheet.dart';
import 'package:cpapp/features/ask/presentation/widgets/ask_create_sheet.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

bool _isDark(Color c) {
  final r = (c.r * 255.0).round();
  final g = (c.g * 255.0).round();
  final b = (c.b * 255.0).round();
  return (0.299 * r + 0.587 * g + 0.114 * b) / 255 < 0.55;
}

/// Parses `'#rrggbb,#rrggbb'` (gradient) or `'#rrggbb'` (legacy solid) into a
/// [LinearGradient]. Returns null for null/empty input.
LinearGradient? _gradientFromEncoded(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  final parts = encoded.split(',');
  if (parts.length >= 2) {
    final c1 = _hexColor(parts[0].trim());
    final c2 = _hexColor(parts[1].trim());
    return LinearGradient(
      colors: [c1, c2],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
  final c = _hexColor(encoded.trim());
  return LinearGradient(colors: [c, c]);
}

/// Returns the representative (start) colour of an encoded background for
/// luminance checks. Returns null when there is no background.
Color? _startColor(String? encoded) {
  if (encoded == null || encoded.isEmpty) return null;
  return _hexColor(encoded.split(',').first.trim());
}

double _fontSizePx(String key) {
  switch (key) {
    case 'large':
      return 24;
    case 'medium':
      return 18;
    default:
      return 14;
  }
}

TextAlign _parseAlign(String v) {
  switch (v) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    default:
      return TextAlign.left;
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class AskPostCard extends ConsumerWidget {
  const AskPostCard({super.key, required this.post});

  final AskPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid =
        ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
    final isLiked = ref.watch(
      askFeedProvider.select((s) => s.isLiked(post.id)),
    );
    final isMine = post.authorUid == myUid;

    void openAuthorProfile() {
      if (isMine) {
        context.push(Routes.profile);
      } else {
        context.push(
          Routes.realtorProfile.replaceFirst(':realtorId', post.authorUid),
        );
      }
    }

    final bgStart =
        post.hasBackground ? _startColor(post.backgroundColorHex) : null;
    final textOnBg = bgStart != null
        ? (_isDark(bgStart) ? Colors.white : AppColors.navyDark)
        : (isDark ? AppColors.white : AppColors.navyDark);
    final align = _parseAlign(post.textAlign);
    final fw = post.isBold ? FontWeight.w800 : FontWeight.normal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: openAuthorProfile,
                  child: _Avatar(
                    name: post.authorName,
                    photoUrl: post.authorPhotoUrl,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: openAuthorProfile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName.isEmpty ? 'Broker' : post.authorName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.white
                                : AppColors.navyDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _ago(post.createdAt),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMine)
                  IconButton(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                    onPressed: () => _showOwnerMenu(context, ref),
                  )
                else
                  IconButton(
                    icon: Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                    tooltip: 'Report',
                    onPressed: () => _showReportSheet(context, ref),
                  ),
              ],
            ),
          ),

          // ── Background colour card (text-only coloured posts) ───────────
          if (post.hasBackground && !post.hasImage)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: _gradientFromEncoded(post.backgroundColorHex),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Center(
                  child: Text(
                    post.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _fontSizePx(post.fontSize),
                      color: textOnBg,
                      fontWeight: fw,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            )

          // ── Plain text body ─────────────────────────────────────────────
          else if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                post.text,
                textAlign: align,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.white : AppColors.navyDark,
                  fontWeight: fw,
                  height: 1.35,
                ),
              ),
            ),

          // ── Image — natural aspect ratio ────────────────────────────────
          if (post.hasImage)
            AspectRatio(
              aspectRatio: post.imageAspectRatio ?? (4 / 5),
              child: CachedNetworkImage(
                imageUrl: post.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? AppColors.navyMid : AppColors.surfaceLight,
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDark ? AppColors.navyMid : AppColors.surfaceLight,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),

          // ── Action bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
            child: Row(
              children: [
                _ActionButton(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor:
                      isLiked ? AppColors.error : AppColors.textSecondary,
                  label: '${post.likesCount}',
                  onTap: () =>
                      ref.read(askFeedProvider.notifier).toggleLike(post.id),
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  iconColor: AppColors.textSecondary,
                  label: '${post.commentsCount}',
                  onTap: () => _openComments(context),
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  iconColor: AppColors.textSecondary,
                  label: '',
                  onTap: () => _sharePost(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sharePost(BuildContext context) {
    final text = DeepLinkService.postShareText(
      authorName: post.authorName,
      bodyPreview: post.text,
      postId: post.id,
    );
    Share.share(text, subject: '${post.authorName} on DigiProp');
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AskCommentsSheet(post: post),
    );
  }

  void _showOwnerMenu(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Edit ──────────────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.gold),
              title: Text(
                l.askEdit,
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.navyDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AskCreateSheet(initialPost: post),
                );
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            // ── Delete ────────────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                l.askDelete,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    content: Text(l.askDeleteConfirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dCtx).pop(false),
                        child: Text(l.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dCtx).pop(true),
                        child: Text(
                          l.askDelete,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(askFeedProvider.notifier).deletePost(post.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const reasons = [
      'Spam or scam',
      'Misleading information',
      'Inappropriate content',
      'Harassment or abuse',
      'Other',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Report post',
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.white : AppColors.navyDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Divider(height: 1),
            ...reasons.map(
              (reason) => ListTile(
                title: Text(
                  reason,
                  style: TextStyle(
                    color: isDark ? AppColors.white : AppColors.navyDark,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final ok = await ref
                      .read(askFeedProvider.notifier)
                      .reportPost(postId: post.id, reason: reason);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Thanks for your report. We\'ll review it.'
                              : 'Could not submit report. Please try again.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.photoUrl});
  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.gold.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.navyDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
