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

  Future<Connection> follow({
    required String followerUid,
    required String followingUid,
  });

  Future<void> unfollow({
    required String connectionId,
    required String uid1,
    required String uid2,
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
          .limit(limit + 1);

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
      // Fetch both directions: people this user follows and people following them
      final asFollower = _connections
          .where('followerId', isEqualTo: uid)
          .get();
      final asFollowing = _connections
          .where('followingId', isEqualTo: uid)
          .get();
      final results = await Future.wait([asFollower, asFollowing]);
      final seen = <String>{};
      final connections = <Connection>[];
      for (final snap in results) {
        for (final doc in snap.docs) {
          if (seen.add(doc.id)) {
            connections.add(ConnectionModel.fromFirestore(doc));
          }
        }
      }
      return connections;
    } catch (e) {
      throw ServerException('Failed to fetch connections: $e');
    }
  }

  @override
  Future<Connection> follow({
    required String followerUid,
    required String followingUid,
  }) async {
    try {
      final id = Connection.idFor(followerUid, followingUid);
      final now = DateTime.now();
      final model = ConnectionModel(
        id: id,
        followerId: followerUid,
        followingId: followingUid,
        createdAt: now,
      );
      final batch = _db.batch();
      batch.set(_connections.doc(id), model.toMap());
      batch.update(
        _users.doc(followerUid),
        {'connectionsCount': FieldValue.increment(1)},
      );
      batch.update(
        _users.doc(followingUid),
        {'connectionsCount': FieldValue.increment(1)},
      );
      await batch.commit();
      return model;
    } catch (e) {
      throw ServerException('Failed to follow: $e');
    }
  }

  @override
  Future<void> unfollow({
    required String connectionId,
    required String uid1,
    required String uid2,
  }) async {
    try {
      final batch = _db.batch();
      batch.delete(_connections.doc(connectionId));
      batch.update(
        _users.doc(uid1),
        {'connectionsCount': FieldValue.increment(-1)},
      );
      batch.update(
        _users.doc(uid2),
        {'connectionsCount': FieldValue.increment(-1)},
      );
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to unfollow: $e');
    }
  }
}
