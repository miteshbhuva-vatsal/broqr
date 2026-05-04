import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';

abstract interface class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> fetchNotifications(
    String uid,
  );

  Future<Either<Failure, Unit>> markAsRead(String uid, String notifId);

  Future<Either<Failure, Unit>> markAllRead(String uid);

  Future<Either<Failure, Unit>> deleteNotification(
    String uid,
    String notifId,
  );

  Future<Either<Failure, Unit>> createNotification({
    required String recipientUid,
    required NotificationType type,
    required String title,
    required String body,
    String? actorUid,
    String? targetId,
  });
}
