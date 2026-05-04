import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/broker_network/data/models/broker_profile_model.dart';
import 'package:cpapp/features/broker_network/data/models/connection_model.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';

abstract interface class NetworkRemoteDataSource {
  Future<List<BrokerProfile>> fetchBrokers({
    required String currentUid,
    String? lastUid,
    int limit = 20,
  });

  Future<BrokerProfile> fetchBrokerProfile(String uid);

  Future<List<Connection>> fetchConnections(String uid);

  Future<Connection> sendConnectionRequest({
    required String senderUid,
    required String receiverUid,
  });

  Future<Connection> acceptConnection(String connectionId);

  Future<void> removeConnection({
    required String connectionId,
    required String uid1,
    required String uid2,
    required bool wasConnected,
  });
}

class NetworkRemoteDataSourceImpl implements NetworkRemoteDataSource {
  const NetworkRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _connections =>
      _db.collection(AppConstants.connectionsCollection);

  @override
  Future<List<BrokerProfile>> fetchBrokers({
    required String currentUid,
    String? lastUid,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _users
          .where('isProfileComplete', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit + 1); // +1 to check hasMore

      if (lastUid != null) {
        final lastDoc = await _users.doc(lastUid).get();
        if (lastDoc.exists) query = query.startAfterDocument(lastDoc);
      }

      final snap = await query.get();
      return snap.docs
          .map((d) => BrokerProfileModel.fromFirestore(d))
          .where((b) => b.uid != currentUid)
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch brokers: $e');
    }
  }

  @override
  Future<BrokerProfile> fetchBrokerProfile(String uid) async {
    try {
      final doc = await _users.doc(uid).get();
      if (!doc.exists) throw const ServerException('Broker not found');
      return BrokerProfileModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to fetch broker profile: $e');
    }
  }

  @override
  Future<List<Connection>> fetchConnections(String uid) async {
    try {
      final snap = await _connections
          .where('participants', arrayContains: uid)
          .get();
      return snap.docs
          .map((d) => ConnectionModel.fromFirestore(d))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch connections: $e');
    }
  }

  @override
  Future<Connection> sendConnectionRequest({
    required String senderUid,
    required String receiverUid,
  }) async {
    try {
      final id = Connection.idFor(senderUid, receiverUid);
      final now = DateTime.now();
      final model = ConnectionModel(
        id: id,
        senderId: senderUid,
        participants: [senderUid, receiverUid],
        status: 'pending',
        createdAt: now,
      );
      await _connections.doc(id).set(model.toMap());
      return model;
    } catch (e) {
      throw ServerException('Failed to send connection request: $e');
    }
  }

  @override
  Future<Connection> acceptConnection(String connectionId) async {
    try {
      // Read current doc to get participant UIDs
      final doc = await _connections.doc(connectionId).get();
      if (!doc.exists) throw const ServerException('Connection not found');
      final current = ConnectionModel.fromFirestore(doc);

      // Batch: update status + increment both users' connectionsCount
      final batch = _db.batch();
      batch.update(
        _connections.doc(connectionId),
        {'status': 'connected'},
      );
      for (final uid in current.participants) {
        batch.update(
          _users.doc(uid),
          {'connectionsCount': FieldValue.increment(1)},
        );
      }
      await batch.commit();

      return ConnectionModel(
        id: current.id,
        senderId: current.senderId,
        participants: current.participants,
        status: 'connected',
        createdAt: current.createdAt,
      );
    } catch (e) {
      throw ServerException('Failed to accept connection: $e');
    }
  }

  @override
  Future<void> removeConnection({
    required String connectionId,
    required String uid1,
    required String uid2,
    required bool wasConnected,
  }) async {
    try {
      final batch = _db.batch();
      batch.delete(_connections.doc(connectionId));
      if (wasConnected) {
        batch.update(
          _users.doc(uid1),
          {'connectionsCount': FieldValue.increment(-1)},
        );
        batch.update(
          _users.doc(uid2),
          {'connectionsCount': FieldValue.increment(-1)},
        );
      }
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to remove connection: $e');
    }
  }
}
