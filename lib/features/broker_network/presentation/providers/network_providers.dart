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

    // Fetch brokers and connections in parallel
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

  void setTab(NetworkTab tab) {
    state = state.copyWith(tab: tab);
  }

  Future<void> sendConnectionRequest(String receiverUid) async {
    final uid = _myUid;
    if (uid.isEmpty) return;

    // Optimistic: mark as pending sent
    final tempMap = Map<String, ConnectionStatus>.from(state.statusMap);
    tempMap[receiverUid] = ConnectionStatus.pendingSent;
    state = state.copyWith(statusMap: tempMap);

    final result = await _repo.sendConnectionRequest(
      senderUid: uid,
      receiverUid: receiverUid,
    );

    result.fold(
      (failure) {
        // Revert on failure
        final revertMap = Map<String, ConnectionStatus>.from(state.statusMap);
        revertMap[receiverUid] = ConnectionStatus.none;
        state = state.copyWith(statusMap: revertMap, error: failure.message);
      },
      (connection) {
        final updated = [...state.connections, connection];
        state = state.copyWith(
          connections: updated,
          statusMap: _buildStatusMap(updated, uid),
        );

        // Fire-and-forget notification to receiver
        final myName =
            ref.read(authStateChangesProvider).valueOrNull?.name ?? 'A broker';
        _notifRepo.createNotification(
          recipientUid: receiverUid,
          type: NotificationType.connectionRequest,
          title: 'New Connection Request',
          body: '$myName wants to connect with you',
          actorUid: uid,
          targetId: connection.id,
        );
      },
    );
  }

  Future<void> acceptConnection(String connectionId, String senderUid) async {
    final uid = _myUid;
    if (uid.isEmpty) return;

    // Optimistic: mark as connected
    final tempMap = Map<String, ConnectionStatus>.from(state.statusMap);
    tempMap[senderUid] = ConnectionStatus.connected;
    state = state.copyWith(statusMap: tempMap);

    final result = await _repo.acceptConnection(connectionId);

    result.fold(
      (failure) {
        final revertMap = Map<String, ConnectionStatus>.from(state.statusMap);
        revertMap[senderUid] = ConnectionStatus.pendingReceived;
        state = state.copyWith(statusMap: revertMap, error: failure.message);
      },
      (connection) {
        final updated = state.connections
            .map((c) => c.id == connectionId ? connection : c)
            .toList();
        state = state.copyWith(
          connections: updated,
          statusMap: _buildStatusMap(updated, uid),
        );

        // Fire-and-forget notification to the original sender
        final myName =
            ref.read(authStateChangesProvider).valueOrNull?.name ?? 'A broker';
        _notifRepo.createNotification(
          recipientUid: senderUid,
          type: NotificationType.connectionAccepted,
          title: 'Connection Accepted',
          body: '$myName accepted your connection request',
          actorUid: uid,
          targetId: connectionId,
        );
      },
    );
  }

  Future<void> removeConnection({
    required String connectionId,
    required String otherUid,
    required bool wasConnected,
  }) async {
    final uid = _myUid;
    if (uid.isEmpty) return;

    // Optimistic: remove immediately
    final updatedConnections =
        state.connections.where((c) => c.id != connectionId).toList();
    final tempMap = Map<String, ConnectionStatus>.from(state.statusMap);
    tempMap[otherUid] = ConnectionStatus.none;
    state = state.copyWith(
      connections: updatedConnections,
      statusMap: tempMap,
    );

    final result = await _repo.removeConnection(
      connectionId: connectionId,
      uid1: uid,
      uid2: otherUid,
      wasConnected: wasConnected,
    );

    result.fold(
      (failure) {
        // Reload to reconcile state on failure
        _load();
      },
      (_) {},
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  Map<String, ConnectionStatus> _buildStatusMap(
    List<Connection> connections,
    String myUid,
  ) {
    final map = <String, ConnectionStatus>{};
    for (final c in connections) {
      final otherUid = c.otherUid(myUid);
      map[otherUid] = c.statusFor(myUid);
    }
    return map;
  }
}

// ── Derived providers ─────────────────────────────────────────────────────────

/// Exposes the UIDs of all accepted connections for the current user.
/// Used by the feed to filter listings to connected brokers only.
final connectedUidsProvider = Provider<List<String>>((ref) {
  final myUid =
      ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
  if (myUid.isEmpty) return [];
  return ref
      .watch(networkProvider)
      .connections
      .where((c) => c.isConnected)
      .map((c) => c.otherUid(myUid))
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
      .where((c) => c.isConnected)
      .map((c) => c.otherUid(myUid))
      .where((uid) => uid.isNotEmpty)
      .toSet();

  if (myConnectedUids.isEmpty) return 0;

  final snap = await FirebaseFirestore.instance
      .collection('connections')
      .where('participants', arrayContains: brokerId)
      .get();

  final brokerConnectedUids = snap.docs
      .where((d) => d['status'] == 'connected')
      .map((d) {
        final parts = (d['participants'] as List<dynamic>).cast<String>();
        return parts.firstWhere((p) => p != brokerId, orElse: () => '');
      })
      .where((uid) => uid.isNotEmpty && uid != myUid)
      .toSet();

  return myConnectedUids.intersection(brokerConnectedUids).length;
});
