import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';

abstract interface class NetworkRepository {
  Future<Either<Failure, List<BrokerProfile>>> fetchBrokers({
    required String currentUid,
    String? lastUid,
    int limit = 20,
  });

  Future<Either<Failure, BrokerProfile>> fetchBrokerProfile(String uid);

  Future<Either<Failure, List<Connection>>> fetchConnections(String uid);

  Future<Either<Failure, Connection>> sendConnectionRequest({
    required String senderUid,
    required String receiverUid,
  });

  Future<Either<Failure, Connection>> acceptConnection(String connectionId);

  Future<Either<Failure, Unit>> removeConnection({
    required String connectionId,
    required String uid1,
    required String uid2,
    required bool wasConnected,
  });
}
