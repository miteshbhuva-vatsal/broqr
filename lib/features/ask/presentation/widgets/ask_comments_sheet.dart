import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/ask/domain/entities/ask_comment.dart';
import 'package:cpapp/features/ask/domain/entities/ask_post.dart';
import 'package:cpapp/features/ask/presentation/providers/ask_providers.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

class AskCommentsSheet extends ConsumerStatefulWidget {
  const AskCommentsSheet({super.key, required this.post});
  final AskPost post;

  @override
  ConsumerState<AskCommentsSheet> createState() => _AskCommentsSheetState();
}

class _AskCommentsSheetState extends ConsumerState<AskCommentsSheet> {
  final _sendController = TextEditingController();
  final _editController = TextEditingController();
  bool _sending = false;
  bool _saving = false;
  String? _editingCommentId;

  @override
  void dispose() {
    _sendController.dispose();
    _editController.dispose();
    super.dispose();
  }

  // ── Send new comment ────────────────────────────────────────────────────────

  Future<void> _send() async {
    final text = _sendController.text.trim();
    if (text.isEmpty || _sending) return;
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    setState(() => _sending = true);
    final result = await ref.read(askRepositoryProvider).addComment(
          postId: widget.post.id,
          authorUid: user.uid,
          authorName: user.name,
          authorPhotoUrl: user.photoUrl,
          text: text,
        );
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
      ),
      (_) => _sendController.clear(),
    );
  }

  // ── Save edited comment ─────────────────────────────────────────────────────

  Future<void> _saveEdit(String commentId) async {
    final text = _editController.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final result = await ref.read(askRepositoryProvider).updateComment(
          postId: widget.post.id,
          commentId: commentId,
          text: text,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editingCommentId = null;
    });
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
      ),
      (_) {},
    );
  }

  void _cancelEdit() => setState(() => _editingCommentId = null);

  // ── Delete comment ──────────────────────────────────────────────────────────

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('Delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error),),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref.read(askRepositoryProvider).deleteComment(
          postId: widget.post.id,
          commentId: commentId,
        );
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: AppColors.error),
      ),
      (_) {},
    );
  }

  // ── Owner context menu ──────────────────────────────────────────────────────

  void _showCommentMenu(AskComment c, bool isDark) {
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
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.gold),
              title: Text(
                'Edit comment',
                style: TextStyle(
                  color: isDark ? AppColors.white : AppColors.navyDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _editController.text = c.text;
                setState(() => _editingCommentId = c.id);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete comment',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                _deleteComment(c.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final myUid = ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
    final commentsAsync = ref.watch(askCommentsProvider(widget.post.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // ── Handle ──────────────────────────────────────────────────
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      l.askComments,
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),

              // ── Comment list ─────────────────────────────────────────────
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Could not load comments',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No comments yet — be the first.',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4,),
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final c = comments[i];
                        final isMine = c.authorUid == myUid;
                        final isEditing = _editingCommentId == c.id;
                        return _CommentRow(
                          comment: c,
                          isDark: isDark,
                          isMine: isMine,
                          isEditing: isEditing,
                          saving: _saving,
                          editController: _editController,
                          onLongPress: isMine
                              ? () => _showCommentMenu(c, isDark)
                              : null,
                          onSaveEdit: () => _saveEdit(c.id),
                          onCancelEdit: _cancelEdit,
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Compose bar ──────────────────────────────────────────────
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _sendController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: l.askWriteComment,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10,),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sending ? null : _send,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navyDark,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                  color: AppColors.navyDark,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Comment row ───────────────────────────────────────────────────────────────

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.isDark,
    required this.isMine,
    required this.isEditing,
    required this.saving,
    required this.editController,
    required this.onLongPress,
    required this.onSaveEdit,
    required this.onCancelEdit,
  });

  final AskComment comment;
  final bool isDark;
  final bool isMine;
  final bool isEditing;
  final bool saving;
  final TextEditingController editController;
  final VoidCallback? onLongPress;
  final VoidCallback onSaveEdit;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isDark ? AppColors.navyMid : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.white : AppColors.navyDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallAvatar(
            name: comment.authorName,
            photoUrl: comment.authorPhotoUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8,),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isEditing
                          ? Border.all(color: AppColors.gold, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                comment.authorName.isEmpty
                                    ? 'Broker'
                                    : comment.authorName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isMine && !isEditing)
                              GestureDetector(
                                onTap: onLongPress,
                                child: const Icon(
                                  Icons.more_horiz_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (isEditing) ...[
                          TextField(
                            controller: editController,
                            autofocus: true,
                            maxLines: null,
                            style: AppTypography.bodySmall
                                .copyWith(color: textColor, height: 1.3),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: saving ? null : onCancelEdit,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4,),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Cancel',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton(
                                onPressed: saving ? null : onSaveEdit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  foregroundColor: AppColors.navyDark,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4,),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: saving
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          color: AppColors.navyDark,
                                        ),
                                      )
                                    : Text(
                                        'Save',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ] else
                          Text(
                            comment.text,
                            style: AppTypography.bodySmall.copyWith(
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.name, required this.photoUrl});
  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: AppColors.surfaceLight,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.gold.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.navyDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
