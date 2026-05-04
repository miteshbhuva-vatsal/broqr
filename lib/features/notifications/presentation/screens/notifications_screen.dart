import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';
import 'package:cpapp/features/notifications/presentation/widgets/notification_tile.dart';

const _navy = Color(0xFF0A1628);
const _gold = Color(0xFFD4A843);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<NotificationState>(notificationsProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red[700],
          ),
        );
        ref.read(notificationsProvider.notifier).clearError();
      }
    });

    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: _gold, fontSize: 13),
              ),
            ),
        ],
        elevation: 0,
      ),
      body: _NotificationsBody(state: state),
    );
  }
}

class _NotificationsBody extends ConsumerWidget {
  const _NotificationsBody({required this.state});
  final NotificationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }

    if (state.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No notifications yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Connection requests and updates will appear here',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _navy,
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final notif = state.notifications[index];
          return NotificationTile(
            notification: notif,
            onTap: () => _handleTap(context, ref, notif),
            onDismiss: () => ref
                .read(notificationsProvider.notifier)
                .deleteNotification(notif.id),
          );
        },
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notif,
  ) {
    if (!notif.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
    }

    switch (notif.type) {
      case NotificationType.connectionRequest:
      case NotificationType.connectionAccepted:
        context.go(Routes.network);

      case NotificationType.listingInquiry:
        context.go(Routes.crm);

      case NotificationType.general:
        break;
    }
  }
}
