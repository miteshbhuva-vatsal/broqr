import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/broker_network/data/datasources/network_remote_datasource.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';
import 'package:cpapp/features/broker_network/domain/repositories/network_repository.dart';

class NetworkRepositoryImpl implements NetworkRepository {
  const NetworkRepositoryImpl({required NetworkRemoteDataSource dataSource})
      : _ds = dataSource;

  final NetworkRemoteDataSource _ds;

  @override
  Future<Either<Failure, List<BrokerProfile>>> fetchBrokers({
    required String currentUid,
    String? lastUid,
    int limit = 20,
  }) async {
    try {
      return Right(await _ds.fetchBrokers(
        currentUid: currentUid,
        lastUid: lastUid,
        limit: limit,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BrokerProfile>> fetchBrokerProfile(String uid) async {
    try {
      return Right(await _ds.fetchBrokerProfile(uid));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Connection>>> fetchConnections(
    String uid,
  ) async {
    try {
      return Right(await _ds.fetchConnections(uid));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Connection>> sendConnectionRequest({
    required String senderUid,
    required String receiverUid,
  }) async {
    try {
      return Right(await _ds.sendConnectionRequest(
        senderUid: senderUid,
        receiverUid: receiverUid,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Connection>> acceptConnection(
    String connectionId,
  ) async {
    try {
      return Right(await _ds.acceptConnection(connectionId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeConnection({
    required String connectionId,
    required String uid1,
    required String uid2,
    required bool wasConnected,
  }) async {
    try {
      await _ds.removeConnection(
        connectionId: connectionId,
        uid1: uid1,
        uid2: uid2,
        wasConnected: wasConnected,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
