import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/chat/data/models/chat_conversation_model.dart';
import 'package:cpapp/features/chat/data/models/chat_message_model.dart';
import 'package:cpapp/features/chat/domain/entities/chat_conversation.dart';
import 'package:cpapp/features/chat/domain/entities/chat_message.dart';

abstract interface class ChatRemoteDataSource {
  Stream<List<ChatConversation>> conversationsStream(String uid);
  Stream<List<ChatMessage>> messagesStream(String chatId);
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String? senderPhoto,
    required String receiverId,
    required String receiverName,
    required String? receiverPhoto,
    required String text,
  });
  Future<void> markRead({required String chatId, required String uid});
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  const ChatRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  @override
  Stream<List<ChatConversation>> conversationsStream(String uid) {
    return _chats
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatConversationModel.fromFirestore(d),)
              .toList(),
        );
  }

  @override
  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ChatMessageModel.fromFirestore(d),).toList(),
        );
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String? senderPhoto,
    required String receiverId,
    required String receiverName,
    required String? receiverPhoto,
    required String text,
  }) async {
    final chatRef = _chats.doc(chatId);
    final chatSnap = await chatRef.get();

    // Create chat document if it doesn't exist
    if (!chatSnap.exists) {
      await chatRef.set(
        ChatConversationModel.newChatMap(
          participants: [senderId, receiverId],
          participantNames: {senderId: senderName, receiverId: receiverName},
          participantPhotos: {senderId: senderPhoto, receiverId: receiverPhoto},
        ),
      );
    }

    // Add message
    final msgRef = chatRef.collection('messages').doc();
    await msgRef.set(ChatMessageModel(
      id: msgRef.id,
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    ).toMap(),);

    // Update chat metadata
    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCounts.$receiverId': FieldValue.increment(1),
      'participantNames.$senderId': senderName,
      'participantNames.$receiverId': receiverName,
      'participantPhotos.$senderId': senderPhoto,
      'participantPhotos.$receiverId': receiverPhoto,
    });
  }

  @override
  Future<void> markRead({required String chatId, required String uid}) async {
    await _chats.doc(chatId).update({'unreadCounts.$uid': 0});
  }
}
