import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/notifications/data/models/notification_model.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationRemoteDataSource {
  Future<List<AppNotification>> fetchNotifications(String uid);

  Future<void> markAsRead(String uid, String notifId);

  Future<void> markAllRead(String uid);

  Future<void> deleteNotification(String uid, String notifId);

  Future<void> createNotification({
    required String recipientUid,
    required NotificationType type,
    required String title,
    required String body,
    String? actorUid,
    String? targetId,
  });
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _items(String uid) => _db
      .collection(AppConstants.notificationsCollection)
      .doc(uid)
      .collection('items');

  @override
  Future<List<AppNotification>> fetchNotifications(String uid) async {
    try {
      final snap = await _items(uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snap.docs.map((d) => NotificationModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch notifications: $e');
    }
  }

  @override
  Future<void> markAsRead(String uid, String notifId) async {
    try {
      await _items(uid).doc(notifId).update({'isRead': true});
    } catch (e) {
      throw ServerException('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<void> markAllRead(String uid) async {
    try {
      final snap = await _items(uid).where('isRead', isEqualTo: false).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to mark all notifications as read: $e');
    }
  }

  @override
  Future<void> deleteNotification(String uid, String notifId) async {
    try {
      await _items(uid).doc(notifId).delete();
    } catch (e) {
      throw ServerException('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> createNotification({
    required String recipientUid,
    required NotificationType type,
    required String title,
    required String body,
    String? actorUid,
    String? targetId,
  }) async {
    try {
      final model = NotificationModel(
        id: '',
        type: type,
        title: title,
        body: body,
        actorUid: actorUid,
        targetId: targetId,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _items(recipientUid).add(model.toMap());
    } catch (_) {
      // Notification delivery is fire-and-forget; swallow errors so callers
      // using unawaited() don't surface unhandled exceptions.
    }
  }
}
