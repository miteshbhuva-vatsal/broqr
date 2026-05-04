import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Logs lightweight app-open events to Firestore for the admin analytics panel.
///
/// Each call writes one document to `appEvents` (with a TTL policy recommended
/// in Firebase Console → Firestore → TTL → 90 days to avoid unbounded growth).
abstract final class AnalyticsService {
  static final _db = FirebaseFirestore.instance;

  /// Call once per authenticated app open to power DAU/app-opens charts.
  static Future<void> logAppOpen(String uid) async {
    try {
      await _db.collection('appEvents').add({
        'event':     'app_open',
        'uid':       uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Also stamp lastSeen on the user doc (used for DAU/MAU queries).
      await _db.collection('users').doc(uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Analytics] logAppOpen error: $e');
    }
  }
}
