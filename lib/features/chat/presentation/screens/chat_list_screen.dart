import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/chat/domain/entities/chat_conversation.dart';
import 'package:cpapp/features/chat/presentation/providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
    final convsAsync = ref.watch(chatConversationsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        foregroundColor: isDark ? AppColors.white : AppColors.navyDark,
        elevation: 0,
        title: Text(
          'Messages',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: convsAsync.when(
        loading: () => const _ShimmerList(),
        error: (e, _) => Center(
          child: Text(
            'Could not load messages',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        data: (convs) {
          if (convs.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 80,
              endIndent: 16,
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
            itemBuilder: (context, index) {
              final conv = convs[index];
              return _ConversationTile(
                conv: conv,
                myUid: myUid,
                isDark: isDark,
                onTap: () {
                  final otherUid = conv.otherUid(myUid);
                  final otherName = conv.nameFor(otherUid);
                  final otherPhoto = conv.photoFor(otherUid);
                  if (myUid.isNotEmpty) {
                    ref
                        .read(chatDataSourceProvider)
                        .markRead(chatId: conv.id, uid: myUid)
                        .ignore();
                  }
                  context.push(
                    '/app/chat/${conv.id}',
                    extra: {
                      'otherName': otherName,
                      'otherPhoto': otherPhoto,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ── Conversation tile ─────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conv,
    required this.myUid,
    required this.isDark,
    required this.onTap,
  });

  final ChatConversation conv;
  final String myUid;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final otherUid = conv.otherUid(myUid);
    final name = conv.nameFor(otherUid);
    final photo = conv.photoFor(otherUid);
    final unread = conv.unreadFor(myUid);
    final hasUnread = unread > 0;
    final nameColor = isDark ? AppColors.white : AppColors.navyDark;
    final previewColor = hasUnread
        ? (isDark ? AppColors.white : AppColors.textPrimary)
        : (isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _Avatar(name: name, photoUrl: photo, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: nameColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.lastMessageAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(conv.lastMessageAt!),
                          style: AppTypography.labelSmall.copyWith(
                            color: hasUnread ? AppColors.gold : AppColors.textHint,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'No messages yet',
                          style: AppTypography.bodySmall.copyWith(
                            color: previewColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: unread),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return mins <= 0 ? 'now' : '${mins}m';
    }
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}

// ── Unread badge ──────────────────────────────────────────────────────────────

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: const BoxDecoration(
        color: AppColors.gold,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: AppColors.navyDark,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.photoUrl,
    required this.size,
  });

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.navyMid,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.navyMid,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.gold,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: AppColors.gold.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 20),
            Text(
              'No conversations yet',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect with brokers to start chatting',
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer loading ───────────────────────────────────────────────────────────

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (_, __) => const _ShimmerTile(),
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  const _ShimmerTile();

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(radius: 26, backgroundColor: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
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
