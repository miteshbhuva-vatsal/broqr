import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

abstract final class ReminderNotificationService {
  static const _channelId = 'cpapp_reminders';
  static const _channelName = 'CRM Reminders';

  static final _plugin = FlutterLocalNotificationsPlugin();

  // Map leadId to a stable positive int notification ID
  static int _notifId(String leadId) => leadId.hashCode.abs() % 0x7FFFFFFF;

  /// Schedules a local notification 1 hour before [reminderAt].
  /// If that moment is already in the past, the call is a no-op.
  static Future<void> schedule({
    required String leadId,
    required String clientName,
    required DateTime reminderAt,
  }) async {
    final fireAt = reminderAt.subtract(const Duration(hours: 1));
    if (!fireAt.isAfter(DateTime.now())) return;

    final tzDateTime = tz.TZDateTime.from(fireAt, tz.local);

    try {
      await _plugin.zonedSchedule(
        _notifId(leadId),
        'Reminder in 1 hour',
        'Follow up with $clientName',
        tzDateTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Reminder] schedule failed: $e');
    }
  }

  /// Cancels a previously scheduled reminder for [leadId].
  static Future<void> cancel(String leadId) async {
    try {
      await _plugin.cancel(_notifId(leadId));
    } catch (e) {
      if (kDebugMode) debugPrint('[Reminder] cancel failed: $e');
    }
  }
}
