import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:cpapp/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/domain/repositories/notification_repository.dart';

part 'notification_providers.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

@riverpod
NotificationRemoteDataSource notificationRemoteDataSource(Ref ref) {
  return NotificationRemoteDataSourceImpl(
    firestore: FirebaseFirestore.instance,
  );
}

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepositoryImpl(
    dataSource: ref.watch(notificationRemoteDataSourceProvider),
  );
}

// ── State ─────────────────────────────────────────────────────────────────────

class NotificationState {
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

@riverpod
class Notifications extends _$Notifications {
  @override
  NotificationState build() {
    Future.microtask(() => _load());
    return const NotificationState(isLoading: true);
  }

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  String get _uid =>
      ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';

  Future<void> _load() async {
    final uid = _uid;
    if (uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final result = await _repo.fetchNotifications(uid);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (notifs) => state = state.copyWith(
        isLoading: false,
        notifications: notifs,
        clearError: true,
      ),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load();
  }

  Future<void> markAsRead(String notifId) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    // Optimistic update
    final updated = state.notifications
        .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(notifications: updated);

    await _repo.markAsRead(uid, notifId);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid.isEmpty) return;

    // Optimistic update
    final updated =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);

    await _repo.markAllRead(uid);
  }

  Future<void> deleteNotification(String notifId) async {
    final uid = _uid;
    if (uid.isEmpty) return;

    // Optimistic remove
    final updated =
        state.notifications.where((n) => n.id != notifId).toList();
    state = state.copyWith(notifications: updated);

    await _repo.deleteNotification(uid, notifId);
  }

  void clearError() => state = state.copyWith(clearError: true);
}
