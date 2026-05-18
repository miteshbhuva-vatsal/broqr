import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/chat/data/models/chat_conversation_model.dart';
import 'package:cpapp/features/chat/data/models/chat_message_model.dart';
import 'package:cpapp/features/chat/domain/entities/chat_conversation.dart';
import 'package:cpapp/features/chat/domain/entities/chat_message.dart';

abstract interface class ChatRemoteDataSource {
  Stream<List<ChatConversation>> conversationsStream(String uid);

  /// Live stream of the most recent [limit] messages, oldest-first.
  Stream<List<ChatMessage>> messagesStream(String chatId, {int limit = 50});

  /// One-shot fetch of messages strictly older than [beforeTimestamp],
  /// returned oldest-first (ready to prepend in UI order).
  Future<List<ChatMessage>> fetchOlderMessages({
    required String chatId,
    required DateTime beforeTimestamp,
    int limit = 50,
  });

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
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatConversationModel.fromFirestore(d))
              .toList(),
        );
  }

  @override
  Stream<List<ChatMessage>> messagesStream(String chatId, {int limit = 50}) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ChatMessageModel.fromFirestore(d)).toList(),
        );
  }

  @override
  Future<List<ChatMessage>> fetchOlderMessages({
    required String chatId,
    required DateTime beforeTimestamp,
    int limit = 50,
  }) async {
    // Descending query so cursor pagination works; reverse to ASC for the UI,
    // which renders oldest-first.
    final snap = await _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfter([Timestamp.fromDate(beforeTimestamp)])
        .limit(limit)
        .get();
    // reversed is lazy; a single toList() materialises in ascending order.
    return snap.docs.reversed
        .map((d) => ChatMessageModel.fromFirestore(d))
        .toList();
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
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw const ServerException('Message cannot be empty');
    if (trimmed.length > AppConstants.maxMessageLength) {
      throw const ServerException('Message exceeds maximum length');
    }
    final chatRef = _chats.doc(chatId);

    // Write chat doc first so Firestore rules can read participants when the
    // message create rule calls get(chatDoc) — batch writes see pre-commit
    // state, which causes permission-denied on first message.
    await chatRef.set(
      {
        'participants': [senderId, receiverId],
        'participantNames': {senderId: senderName, receiverId: receiverName},
        'participantPhotos': {senderId: senderPhoto, receiverId: receiverPhoto},
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCounts.$receiverId': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );

    // Write message after chat doc exists — rule get() now succeeds.
    final msgRef = chatRef.collection('messages').doc();
    await msgRef.set(
      ChatMessageModel(
        id: msgRef.id,
        senderId: senderId,
        text: trimmed,
        timestamp: DateTime.now(),
      ).toMap(),
    );
  }

  @override
  Future<void> markRead({required String chatId, required String uid}) async {
    await _chats.doc(chatId).update({'unreadCounts.$uid': 0});
  }
}
