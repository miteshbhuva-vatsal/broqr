import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/chat/domain/entities/chat_message.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.text,
    required super.timestamp,
    super.read,
  });

  factory ChatMessageModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ChatMessageModel(
      id: doc.id,
      senderId: d['senderId'] as String,
      text: d['text'] as String? ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: d['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'timestamp': Timestamp.fromDate(timestamp),
        'read': read,
      };
}
