import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cpapp/firebase_options.dart';

/// Initialises Firebase on app start.
/// Call [FirebaseService.init] before runApp.
abstract final class FirebaseService {
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Bounded persistent cache: 50 MB on device.
    // Firestore serves reads from local cache first → fewer network round-trips
    // and zero reads billed for cached data that hasn't changed.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 52428800, // 50 MB
    );

    // App Check: debug provider for debug builds, Play Integrity for release.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttest,
    );

    if (kDebugMode) {
      debugPrint('[FirebaseService] Firebase initialised.');
    }
  }
}
