import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/chat/domain/entities/chat_message.dart';
import 'package:cpapp/features/chat/presentation/providers/chat_providers.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    this.otherPhoto,
    this.otherUid,
  });

  final String chatId;
  final String otherName;
  final String? otherPhoto;
  final String? otherUid;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final myUid =
          ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
      if (myUid.isNotEmpty) {
        ref
            .read(chatDataSourceProvider)
            .markRead(chatId: widget.chatId, uid: myUid)
            .ignore();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;
    _textController.clear();
    setState(() => _isSending = true);
    try {
      final myUser = ref.read(authStateChangesProvider).valueOrNull;
      if (myUser == null) return;

      final receiverId = widget.otherUid?.isNotEmpty == true
          ? widget.otherUid!
          : widget.chatId
              .split('_')
              .firstWhere((p) => p != myUser.uid, orElse: () => '');

      if (receiverId.isEmpty) return;

      await ref.read(chatDataSourceProvider).sendMessage(
            chatId: widget.chatId,
            senderId: myUser.uid,
            senderName: myUser.name,
            senderPhoto: myUser.photoUrl,
            receiverId: receiverId,
            receiverName: widget.otherName,
            receiverPhoto: widget.otherPhoto,
            text: text,
          );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid =
        ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
    final state = ref.watch(chatMessagesProvider(widget.chatId));

    ref.listen<ChatMessagesState>(chatMessagesProvider(widget.chatId),
        (prev, next) {
      final prevTailId = prev?.streamMessages.isNotEmpty == true
          ? prev!.streamMessages.last.id
          : null;
      final nextTailId = next.streamMessages.isNotEmpty
          ? next.streamMessages.last.id
          : null;
      if (nextTailId != null && nextTailId != prevTailId) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        foregroundColor: isDark ? AppColors.white : AppColors.navyDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            _SmallAvatar(
              name: widget.otherName,
              photoUrl: widget.otherPhoto,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherName,
                style: AppTypography.titleSmall.copyWith(
                  color: isDark ? AppColors.white : AppColors.navyDark,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (_) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  );
                }
                if (state.error != null && state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Could not load messages',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                if (state.messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Send a message to start chatting',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                final messages = state.messages;
                final showFooter = state.isLoadingMore;
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels <= 80 &&
                        !state.isLoadingMore &&
                        state.hasMore &&
                        state.messages.isNotEmpty) {
                      ref
                          .read(chatMessagesProvider(widget.chatId).notifier)
                          .loadOlder();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: messages.length + (showFooter ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (showFooter && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        );
                      }
                      final msgIndex = showFooter ? index - 1 : index;
                      final msg = messages[msgIndex];
                      final isMine = msg.senderId == myUid;
                      final showDateSeparator = msgIndex == 0 ||
                          !_sameDay(
                            messages[msgIndex - 1].timestamp,
                            msg.timestamp,
                          );
                      return Column(
                        children: [
                          if (showDateSeparator)
                            _DateSeparator(date: msg.timestamp, isDark: isDark),
                          _MessageBubble(
                            message: msg,
                            isMine: isMine,
                            isDark: isDark,
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
          _InputBar(
            controller: _textController,
            isSending: _isSending,
            isDark: isDark,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isDark,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);
    final receivedBg = isDark ? AppColors.surfaceDark : AppColors.white;
    final receivedBorder = isDark ? AppColors.borderDark : AppColors.border;
    final receivedText = isDark ? AppColors.white : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment:
                isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMine ? AppColors.gold : receivedBg,
                borderRadius: isMine
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                border: isMine
                    ? null
                    : Border.all(color: receivedBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: isMine ? AppColors.navyDark : receivedText,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              timeStr,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date separator ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date, required this.isDark});
  final DateTime date;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Yesterday';
    } else if (diff < 7) {
      label = DateFormat('EEEE').format(date);
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    final divColor = isDark ? AppColors.borderDark : AppColors.border;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: divColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          Expanded(child: Divider(color: divColor)),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.isDark,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final bool isDark;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final barBg = isDark ? AppColors.navyMid : AppColors.white;
    final fieldBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final fieldBorder = isDark ? AppColors.borderDark : AppColors.border;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.textOnDarkSecondary : AppColors.textHint;

    return Container(
      color: barBg,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: fieldBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMedium.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isSending ? null : onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSending
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.navyDark,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: AppColors.navyDark,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small avatar for AppBar ───────────────────────────────────────────────────

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.navyMid,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.navyMid,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.gold,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
