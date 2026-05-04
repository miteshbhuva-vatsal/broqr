import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cpapp/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

// Top-level handler required by firebase_messaging for background/terminated state.
// Must be annotated with @pragma so it is not tree-shaken in release builds.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('[FCM] Background message: ${message.messageId}');
  }
}

/// Handles Firebase Cloud Messaging setup, local notification display,
/// and FCM token persistence to Firestore.
///
/// Requires push notification entitlements configured in Xcode (iOS)
/// and the google-services.json present (Android).
abstract final class FcmService {
  static const _channelId = 'cpapp_high';
  static const _channelName = 'CPApp Notifications';

  static final _localNotifs = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Register the background handler before anything else
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Android notification channel (required for Android 8+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _localNotifs
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // iOS: show notifications even when app is in foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifs.initialize(initSettings);

    // Show a local notification for messages received while app is open
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifs.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );

      if (kDebugMode) {
        debugPrint('[FCM] Foreground message: ${notification.title}');
      }
    });
  }

  /// Requests notification permission (iOS + Android 13+) and saves the
  /// FCM token to the user's Firestore document.
  static Future<void> setupForUser(String uid) async {
    // Request permission (no-op on Android < 13)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) debugPrint('[FCM] Permission denied');
      return;
    }

    await _saveToken(uid);

    // Refresh token if it rotates (e.g. on reinstall)
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _writeToken(uid, token);
    });
  }

  static Future<void> _saveToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _writeToken(uid, token);
    } catch (e) {
      // FCM token unavailable (emulator, no Google Play Services, network issue).
      // Non-fatal — push notifications simply won't work for this session.
      if (kDebugMode) debugPrint('[FCM] getToken failed: $e');
    }
  }

  static Future<void> _writeToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
      if (kDebugMode) debugPrint('[FCM] Token saved for $uid');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Token write failed: $e');
    }
  }
}
