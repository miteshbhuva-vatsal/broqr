import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/broker_network/data/datasources/network_remote_datasource.dart';
import 'package:cpapp/features/broker_network/data/repositories/network_repository_impl.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';
import 'package:cpapp/features/broker_network/domain/repositories/network_repository.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/domain/repositories/notification_repository.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';

part 'network_providers.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

@riverpod
NetworkRemoteDataSource networkRemoteDataSource(Ref ref) {
  return NetworkRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
}

@riverpod
NetworkRepository networkRepository(Ref ref) {
  return NetworkRepositoryImpl(
    dataSource: ref.watch(networkRemoteDataSourceProvider),
  );
}

// ── Network tab enum ─────────────────────────────────────────────────────────

enum NetworkTab { discover, connections }

// ── State ─────────────────────────────────────────────────────────────────────

class NetworkState {
  const NetworkState({
    this.tab = NetworkTab.discover,
    this.brokers = const [],
    this.connections = const [],
    this.statusMap = const {},
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final NetworkTab tab;
  final List<BrokerProfile> brokers;
  final List<Connection> connections;

  /// uid → ConnectionStatus for quick O(1) lookup in cards
  final Map<String, ConnectionStatus> statusMap;

  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  ConnectionStatus statusFor(String uid) =>
      statusMap[uid] ?? ConnectionStatus.none;

  NetworkState copyWith({
    NetworkTab? tab,
    List<BrokerProfile>? brokers,
    List<Connection>? connections,
    Map<String, ConnectionStatus>? statusMap,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return NetworkState(
      tab: tab ?? this.tab,
      brokers: brokers ?? this.brokers,
      connections: connections ?? this.connections,
      statusMap: statusMap ?? this.statusMap,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class Network extends _$Network {
  static const int _pageSize = 20;

  @override
  NetworkState build() {
    Future.microtask(() => _load());
    return const NetworkState(isLoading: true);
  }

  NetworkRepository get _repo => ref.read(networkRepositoryProvider);

  NotificationRepository get _notifRepo =>
      ref.read(notificationRepositoryProvider);

  String get _myUid =>
      ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';

  Future<void> _load() async {
    final uid = _myUid;
    if (uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final brokersFuture = _repo.fetchBrokers(
      currentUid: uid,
      limit: _pageSize,
    );
    final connectionsFuture = _repo.fetchConnections(uid);

    final brokersResult = await brokersFuture;
    final connectionsResult = await connectionsFuture;

    final connections = connectionsResult.fold((_) => <Connection>[], (c) => c);
    final statusMap = _buildStatusMap(connections, uid);

    brokersResult.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (brokers) => state = state.copyWith(
        isLoading: false,
        brokers: brokers,
        connections: connections,
        statusMap: statusMap,
        hasMore: brokers.length >= _pageSize,
        clearError: true,
      ),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final uid = _myUid;
    if (uid.isEmpty) return;

    state = state.copyWith(isLoadingMore: true);
    final lastUid = state.brokers.isNotEmpty ? state.brokers.last.uid : null;
    final result = await _repo.fetchBrokers(
      currentUid: uid,
      lastUid: lastUid,
      limit: _pageSize,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      ),
      (newBrokers) => state = state.copyWith(
        isLoadingMore: false,
        brokers: [...state.brokers, ...newBrokers],
        hasMore: newBrokers.length >= _pageSize,
      ),
    );
  }

  void setTab(NetworkTab tab) => state = state.copyWith(tab: tab);

  Future<void> follow(String targetUid) async {
    final uid = _myUid;
    if (uid.isEmpty) return;

    // Optimistic update
    final tempMap = Map<String, ConnectionStatus>.from(state.statusMap);
    tempMap[targetUid] = ConnectionStatus.following;
    state = state.copyWith(statusMap: tempMap);

    final result = await _repo.follow(
      followerUid: uid,
      followingUid: targetUid,
    );

    result.fold(
      (failure) {
        final revertMap = Map<String, ConnectionStatus>.from(state.statusMap);
        revertMap[targetUid] = ConnectionStatus.none;
        state = state.copyWith(statusMap: revertMap, error: failure.message);
      },
      (connection) {
        final updated = [...state.connections, connection];
        state = state.copyWith(
          connections: updated,
          statusMap: _buildStatusMap(updated, uid),
        );

        // Notify the person being followed
        final myName =
            ref.read(authStateChangesProvider).valueOrNull?.name ?? 'A broker';
        _notifRepo.createNotification(
          recipientUid: targetUid,
          type: NotificationType.connectionAccepted,
          title: 'New Follower',
          body: '$myName started following you',
          actorUid: uid,
          targetId: connection.id,
        );
      },
    );
  }

  Future<void> unfollow({
    required String connectionId,
    required String otherUid,
  }) async {
    final uid = _myUid;
    if (uid.isEmpty) return;

    // Optimistic update
    final updatedConnections =
        state.connections.where((c) => c.id != connectionId).toList();
    final tempMap = Map<String, ConnectionStatus>.from(state.statusMap);
    tempMap[otherUid] = ConnectionStatus.none;
    state = state.copyWith(
      connections: updatedConnections,
      statusMap: tempMap,
    );

    final result = await _repo.unfollow(
      connectionId: connectionId,
      uid1: uid,
      uid2: otherUid,
    );

    result.fold(
      (failure) => _load(), // Reload to reconcile on failure
      (_) {},
    );
  }

  // Keep for backward compat — delegates to follow()
  Future<void> sendConnectionRequest(String receiverUid) => follow(receiverUid);

  void clearError() => state = state.copyWith(clearError: true);

  Map<String, ConnectionStatus> _buildStatusMap(
    List<Connection> connections,
    String myUid,
  ) {
    final map = <String, ConnectionStatus>{};
    for (final c in connections) {
      final otherUid = c.otherUid(myUid);
      if (otherUid.isNotEmpty) {
        map[otherUid] = ConnectionStatus.following;
      }
    }
    return map;
  }
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// UIDs of everyone the current user follows or is followed by.
final connectedUidsProvider = Provider<List<String>>((ref) {
  final myUid =
      ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
  if (myUid.isEmpty) return [];
  return ref
      .watch(networkProvider)
      .connections
      .map((c) => c.otherUid(myUid))
      .where((uid) => uid.isNotEmpty)
      .toList();
});

/// Returns the count of mutual connections between the current user and [brokerId].
final mutualConnectionsCountProvider =
    FutureProvider.family<int, String>((ref, brokerId) async {
  final myUid =
      ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
  if (myUid.isEmpty || brokerId == myUid) return 0;

  final myConnectedUids = ref
      .read(networkProvider)
      .connections
      .map((c) => c.otherUid(myUid))
      .where((uid) => uid.isNotEmpty)
      .toSet();

  if (myConnectedUids.isEmpty) return 0;

  final followerSnap = await FirebaseFirestore.instance
      .collection('connections')
      .where('followerId', isEqualTo: brokerId)
      .get();
  final followingSnap = await FirebaseFirestore.instance
      .collection('connections')
      .where('followingId', isEqualTo: brokerId)
      .get();

  final brokerConnectedUids = {
    ...followerSnap.docs.map((d) => d['followingId'] as String? ?? ''),
    ...followingSnap.docs.map((d) => d['followerId'] as String? ?? ''),
  }..removeAll(['', myUid, brokerId]);

  return myConnectedUids.intersection(brokerConnectedUids).length;
});
