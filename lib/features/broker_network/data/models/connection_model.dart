import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';

class ConnectionModel extends Connection {
  const ConnectionModel({
    required super.id,
    required super.followerId,
    required super.followingId,
    required super.createdAt,
  });

  factory ConnectionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    // Support legacy docs that used senderId/participants
    final followerId = d['followerId'] as String?
        ?? d['senderId'] as String? ?? '';
    final participants = d['participants'] != null
        ? List<String>.from(d['participants'] as List)
        : <String>[];
    final followingId = d['followingId'] as String?
        ?? participants.firstWhere((p) => p != followerId, orElse: () => '');

    return ConnectionModel(
      id: doc.id,
      followerId: followerId,
      followingId: followingId,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
