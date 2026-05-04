import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required NotificationRemoteDataSource dataSource,
  }) : _ds = dataSource;

  final NotificationRemoteDataSource _ds;

  @override
  Future<Either<Failure, List<AppNotification>>> fetchNotifications(
    String uid,
  ) async {
    try {
      return Right(await _ds.fetchNotifications(uid));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(
    String uid,
    String notifId,
  ) async {
    try {
      await _ds.markAsRead(uid, notifId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markAllRead(String uid) async {
    try {
      await _ds.markAllRead(uid);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteNotification(
    String uid,
    String notifId,
  ) async {
    try {
      await _ds.deleteNotification(uid, notifId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> createNotification({
    required String recipientUid,
    required NotificationType type,
    required String title,
    required String body,
    String? actorUid,
    String? targetId,
  }) async {
    try {
      await _ds.createNotification(
        recipientUid: recipientUid,
        type: type,
        title: title,
        body: body,
        actorUid: actorUid,
        targetId: targetId,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
