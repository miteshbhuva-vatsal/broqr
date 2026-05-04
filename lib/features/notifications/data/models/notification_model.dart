import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
    super.actorUid,
    super.targetId,
  });

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return NotificationModel(
      id: doc.id,
      type: NotificationType.fromString(d['type'] as String?),
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      actorUid: d['actorUid'] as String?,
      targetId: d['targetId'] as String?,
      isRead: d['isRead'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.key,
        'title': title,
        'body': body,
        'actorUid': actorUid,
        'targetId': targetId,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
