import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';

class ConnectionModel extends Connection {
  const ConnectionModel({
    required super.id,
    required super.senderId,
    required super.participants,
    required super.status,
    required super.createdAt,
  });

  factory ConnectionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ConnectionModel(
      id: doc.id,
      senderId: d['senderId'] as String,
      participants: List<String>.from(d['participants'] as List),
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'participants': participants,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
