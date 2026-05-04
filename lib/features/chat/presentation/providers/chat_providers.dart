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

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatId) {
  return ref.watch(chatDataSourceProvider).messagesStream(chatId);
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
