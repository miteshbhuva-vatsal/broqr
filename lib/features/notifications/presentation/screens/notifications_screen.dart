import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';
import 'package:cpapp/features/notifications/presentation/widgets/notification_tile.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<NotificationState>(notificationsProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(notificationsProvider.notifier).clearError();
      }
    });

    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        foregroundColor: isDark ? AppColors.white : AppColors.navyDark,
        elevation: 0,
        title: Row(
          children: [
            Text(
              AppLocalizations.of(context).notificationsTitle,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (state.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
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
              child: Text(
                AppLocalizations.of(context).markAllRead,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.gold,
                ),
              ),
            ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (state.notifications.isEmpty) {
      final l = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              l.noNotificationsYet,
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.notificationsSubtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
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
        context.go(Routes.realtors);

      case NotificationType.listingInquiry:
      case NotificationType.newListing:
        if (notif.targetId != null) {
          context.push(Routes.listingDetail.replaceFirst(':listingId', notif.targetId!));
        } else {
          context.go(Routes.feed);
        }

      case NotificationType.newLead:
        context.go(Routes.crm);

      case NotificationType.reminderDue:
        context.go(Routes.crm);

      case NotificationType.general:
        break;
    }
  }
}
