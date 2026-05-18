import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.white : AppColors.navyDark;
    final bodyColor = isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary;
    final timeColor = isDark ? AppColors.textOnDarkSecondary.withValues(alpha: 0.7) : AppColors.textHint;
    final unreadBg = isDark
        ? AppColors.gold.withValues(alpha: 0.07)
        : AppColors.navyDark.withValues(alpha: 0.04);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notification.isRead ? null : unreadBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeIcon(type: notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: titleColor,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: AppTypography.bodySmall.copyWith(
                        color: bodyColor,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: AppTypography.labelSmall.copyWith(
                        color: timeColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.connectionRequest  => (Icons.person_add_outlined,      AppColors.navyMid),
      NotificationType.connectionAccepted => (Icons.handshake_outlined,        AppColors.success),
      NotificationType.listingInquiry     => (Icons.chat_bubble_outline,       AppColors.gold),
      NotificationType.newListing         => (Icons.home_work_outlined,        AppColors.gold),
      NotificationType.newLead            => (Icons.person_add_outlined,       AppColors.success),
      NotificationType.reminderDue        => (Icons.alarm_outlined,            AppColors.warning),
      NotificationType.general            => (Icons.notifications_outlined,    AppColors.textSecondary),
    };

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
