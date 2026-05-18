import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/chat/domain/entities/chat_conversation.dart';

class ChatConversationModel extends ChatConversation {
  const ChatConversationModel({
    required super.id,
    required super.participants,
    super.lastMessage,
    super.lastMessageAt,
    super.lastSenderId,
    super.participantNames,
    super.participantPhotos,
    super.unreadCounts,
  });

  factory ChatConversationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return ChatConversationModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] as List? ?? []),
      lastMessage: d['lastMessage'] as String?,
      lastMessageAt:
          (d['lastMessageAt'] as Timestamp?)?.toDate(),
      lastSenderId: d['lastSenderId'] as String?,
      participantNames: Map<String, String>.from(
        d['participantNames'] as Map? ?? {},
      ),
      participantPhotos: Map<String, String?>.from(
        d['participantPhotos'] as Map? ?? {},
      ),
      unreadCounts: (d['unreadCounts'] as Map? ?? {}).map(
        (k, v) => MapEntry(k as String, (v as num).toInt()),
      ),
    );
  }

  static Map<String, dynamic> newChatMap({
    required List<String> participants,
    required Map<String, String> participantNames,
    required Map<String, String?> participantPhotos,
  }) =>
      {
        'participants': participants,
        'participantNames': participantNames,
        'participantPhotos': participantPhotos,
        'unreadCounts': {for (final p in participants) p: 0},
        'lastMessage': null,
        'lastMessageAt': null,
        'lastSenderId': null,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
