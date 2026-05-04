import 'package:equatable/equatable.dart';

class ChatConversation extends Equatable {
  const ChatConversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
    this.participantNames = const {},
    this.participantPhotos = const {},
    this.unreadCounts = const {},
  });

  final String id; // = Connection.idFor(uid1, uid2)
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final Map<String, String> participantNames;   // uid → display name
  final Map<String, String?> participantPhotos; // uid → photoUrl
  final Map<String, int> unreadCounts;          // uid → unread count

  String otherUid(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  String nameFor(String uid) => participantNames[uid] ?? 'Unknown';
  String? photoFor(String uid) => participantPhotos[uid];
  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  @override
  List<Object?> get props => [id, lastMessageAt];
}
