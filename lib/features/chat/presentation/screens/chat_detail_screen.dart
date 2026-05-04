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
  });

  final String chatId;
  final String otherName;
  final String? otherPhoto;

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
    // Mark read when entering the screen
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
      await ref.read(chatSendProvider)(widget.chatId, text);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid =
        ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    // Scroll to bottom when new messages arrive
    ref.listen(chatMessagesProvider(widget.chatId), (_, next) {
      if (next.hasValue) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
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
                  color: AppColors.white,
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
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.navyDark),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Could not load messages',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Send a message to start chatting',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg.senderId == myUid;
                    final showDateSeparator = index == 0 ||
                        !_sameDay(
                          messages[index - 1].timestamp,
                          msg.timestamp,
                        );
                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(date: msg.timestamp),
                        _MessageBubble(message: msg, isMine: isMine),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _InputBar(
            controller: _textController,
            isSending: _isSending,
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
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(message.timestamp);

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
                color: isMine ? AppColors.gold : AppColors.white,
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: isMine ? AppColors.navyDark : AppColors.textPrimary,
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
  const _DateSeparator({required this.date});
  final DateTime date;

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
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
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
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
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
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
