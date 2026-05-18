import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/constants/app_constants.dart';

// ── Localities for a given city, ordered by usage ─────────────────────────────

final localitiesProvider =
    StreamProvider.family<List<String>, String>((ref, city) {
  if (city.trim().isEmpty) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection(AppConstants.localitiesCollection)
      .where('city', isEqualTo: city.trim())
      .orderBy('usageCount', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => d.data()['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),);
});

// ── Save or increment a locality for a specific city ──────────────────────────

Future<void> addLocality(String name, String city) async {
  if (name.trim().isEmpty || city.trim().isEmpty) return;
  final cityNorm = city.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  final areaNorm = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  final ref = FirebaseFirestore.instance
      .collection(AppConstants.localitiesCollection)
      .doc('${cityNorm}_$areaNorm');
  await ref.set({
    'name': name.trim(),
    'normalized': areaNorm,
    'city': city.trim(),
    'usageCount': FieldValue.increment(1),
  }, SetOptions(merge: true),);
}
