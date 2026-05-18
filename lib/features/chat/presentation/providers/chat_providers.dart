import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:cpapp/features/chat/domain/entities/chat_conversation.dart';
import 'package:cpapp/features/chat/domain/entities/chat_message.dart';

final chatDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(firestore: FirebaseFirestore.instance);
});

final chatConversationsProvider =
    StreamProvider<List<ChatConversation>>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(chatDataSourceProvider).conversationsStream(uid);
});

// ── Messages with pagination ─────────────────────────────────────────────────
//
// Live-streams the most recent page of messages and supports loading older
// messages on demand (scroll-to-top). State holds the streamed page plus any
// loaded older pages, with id-dedup so a re-emission can't duplicate a message
// already shown.

class ChatMessagesState {
  ChatMessagesState({
    this.streamMessages = const [],
    this.olderMessages = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  /// Live tail (oldest-first within the page).
  final List<ChatMessage> streamMessages;

  /// One-shot older pages, prepended in chronological order.
  final List<ChatMessage> olderMessages;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  /// Merged ASC list (oldest first) — id-deduped against the stream window.
  late final List<ChatMessage> messages = _merge();

  List<ChatMessage> _merge() {
    if (olderMessages.isEmpty) return streamMessages;
    final streamIds = {for (final m in streamMessages) m.id};
    final dedupOlder =
        olderMessages.where((m) => !streamIds.contains(m.id)).toList();
    return [...dedupOlder, ...streamMessages];
  }

  ChatMessagesState copyWith({
    List<ChatMessage>? streamMessages,
    List<ChatMessage>? olderMessages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return ChatMessagesState(
      streamMessages: streamMessages ?? this.streamMessages,
      olderMessages: olderMessages ?? this.olderMessages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  ChatMessagesNotifier(this._ds, this._chatId) : super(ChatMessagesState()) {
    _sub = _ds.messagesStream(_chatId).listen(
          (msgs) => state = state.copyWith(
            streamMessages: msgs,
            isLoading: false,
            clearError: true,
          ),
          onError: (Object e) => state = state.copyWith(
            isLoading: false,
            error: e.toString(),
          ),
        );
  }

  final ChatRemoteDataSource _ds;
  final String _chatId;
  StreamSubscription<List<ChatMessage>>? _sub;

  Future<void> loadOlder() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final cursor = state.messages.isEmpty
        ? null
        : state.messages.first.timestamp;
    if (cursor == null) return;

    state = state.copyWith(isLoadingMore: true);
    const pageSize = 50;
    try {
      final older = await _ds.fetchOlderMessages(
        chatId: _chatId,
        beforeTimestamp: cursor,
        limit: pageSize,
      );
      // Older pages prepend (in ASC order) ahead of any previously loaded older.
      state = state.copyWith(
        isLoadingMore: false,
        olderMessages: [...older, ...state.olderMessages],
        hasMore: older.length >= pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier,
    ChatMessagesState, String>((ref, chatId) {
  return ChatMessagesNotifier(ref.watch(chatDataSourceProvider), chatId);
});

// Total unread count across all conversations
final totalUnreadProvider = Provider<int>((ref) {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return 0;
  final convs = ref.watch(chatConversationsProvider).valueOrNull ?? [];
  return convs.fold<int>(0, (acc, c) => acc + c.unreadFor(uid));
});

// Send message action provider
final chatSendProvider =
    Provider<Future<void> Function(String chatId, String text)>((ref) {
  final ds = ref.watch(chatDataSourceProvider);
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  return (chatId, text) async {
    if (user == null || text.trim().isEmpty) return;
    // Derive receiverId from chatId (sorted UIDs joined by '_')
    final parts = chatId.split('_');
    final receiverId =
        parts.firstWhere((p) => p != user.uid, orElse: () => '');
    if (receiverId.isEmpty) return;
    await ds.sendMessage(
      chatId: chatId,
      senderId: user.uid,
      senderName: user.name,
      senderPhoto: user.photoUrl,
      receiverId: receiverId,
      receiverName: '',
      receiverPhoto: null,
      text: text.trim(),
    );
  };
});
