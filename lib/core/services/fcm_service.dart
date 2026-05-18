import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/firebase_options.dart';

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
/// notification tap routing, and FCM token persistence.
///
/// **Init flow:**
/// 1. Call [init] in main() — sets up channel, background handler, foreground display.
/// 2. Call [listenForTaps] once from the root widget after the GoRouter is ready
///    — wires up background tap (onMessageOpenedApp) and terminated-state tap
///    (getInitialMessage), plus local notification tap routing.
abstract final class FcmService {
  static const _channelId = 'cpapp_high';
  static const _channelName = 'DigiProp Notifications';

  static final _localNotifs = FlutterLocalNotificationsPlugin();
  static bool _tapsInitialised = false;

  static Future<void> init() async {
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

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    // onDidReceiveNotificationResponse is called when the user taps a
    // local notification while the app is in the foreground. The payload
    // is the JSON-encoded FCM data map set in [listenForTaps].
    await _localNotifs.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == null) return;
        try {
          final data = Map<String, dynamic>.from(
            jsonDecode(details.payload!) as Map,
          );
          _pendingTapData = data;
        } catch (_) {}
      },
    );
  }

  // Stores notification data that arrived before the router was ready.
  // [listenForTaps] drains this on first call.
  static Map<String, dynamic>? _pendingTapData;

  /// Call once from the root widget after the GoRouter is available.
  /// Guards against being called multiple times across hot-restarts.
  static void listenForTaps(GoRouter router) {
    // Drain any foreground-notification tap that arrived before the router
    if (_pendingTapData != null) {
      _routeFromData(_pendingTapData!, router);
      _pendingTapData = null;
    }

    if (_tapsInitialised) return;
    _tapsInitialised = true;

    // Terminated-state: app opened by tapping a notification.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _routeFromMessage(message, router);
    });

    // Background-state: app was in background, user tapped notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _routeFromMessage(message, router);
    });

    // Foreground: show a local notification with the FCM data as payload
    // so the tap handler above can navigate.
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
        payload: jsonEncode(message.data),
      );

      if (kDebugMode) {
        debugPrint('[FCM] Foreground message: ${notification.title}');
      }
    });
  }

  /// Routes to the correct screen based on the FCM message data.
  /// Expected data keys:
  ///   type: 'chat' | 'lead' | 'listing' | 'broker'
  ///   chatId / leadId / listingId / brokerId — the document ID
  ///   (for chat: otherName and otherPhoto are optional extras)
  static void _routeFromMessage(RemoteMessage message, GoRouter router) {
    _routeFromData(message.data, router);
  }

  static void _routeFromData(Map<String, dynamic> data, GoRouter router) {
    final type = data['type'] as String?;
    if (kDebugMode) debugPrint('[FCM] Routing tap: type=$type data=$data');

    switch (type) {
      case 'chat':
        final chatId = data['chatId'] as String?;
        if (chatId == null || chatId.isEmpty) return;
        router.push(
          Routes.chatDetail.replaceFirst(':chatId', chatId),
          extra: {
            'otherName': data['otherName'] ?? 'Chat',
            'otherPhoto': data['otherPhoto'],
          },
        );

      case 'lead':
        final leadId = data['leadId'] as String?;
        if (leadId == null || leadId.isEmpty) return;
        router.push(Routes.leadDetail.replaceFirst(':leadId', leadId));

      case 'listing':
        final listingId = data['listingId'] as String?;
        if (listingId == null || listingId.isEmpty) return;
        router.push(
          Routes.listingDetail.replaceFirst(':listingId', listingId),
        );

      case 'broker':
        final brokerId = data['brokerId'] as String?;
        if (brokerId == null || brokerId.isEmpty) return;
        router.push(
          Routes.realtorProfile.replaceFirst(':realtorId', brokerId),
        );

      default:
        // Unknown type — go to notifications screen as fallback.
        if (type != null) router.push(Routes.notifications);
    }
  }

  /// Requests notification permission (iOS + Android 13+) and saves the
  /// FCM token to the user's Firestore document.
  static Future<void> setupForUser(String uid) async {
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
