import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:cpapp/core/providers/referral_provider.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';

/// Processes a pending referral after a new user completes their profile.
///
/// Flow:
///   1. New user opens a cpapp:// link → [PendingReferral] is stored.
///   2. New user registers + completes profile setup.
///   3. [processIfPending] is called automatically from [main.dart]'s auth listener.
///   4. The referring broker receives a new CRM lead linked to the shared listing.
///
/// Requires a Firestore single-field index on `users.referralCode` for the
/// lookup query (auto-prompted by Firebase on first run).
abstract final class ReferralService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> processIfPending({
    required WidgetRef ref,
    required AppUser newUser,
  }) async {
    final pending = ref.read(pendingReferralProvider);
    if (pending == null) return;

    if (kDebugMode) {
      debugPrint('[Referral] processing: $pending for ${newUser.name}');
    }

    try {
      // 1. Look up the referring broker by referral code.
      final brokerSnap = await _db
          .collection('users')
          .where('referralCode', isEqualTo: pending.referralCode)
          .limit(1)
          .get();

      if (brokerSnap.docs.isEmpty) {
        if (kDebugMode) debugPrint('[Referral] no broker found for code ${pending.referralCode}');
        return;
      }

      final brokerDoc = brokerSnap.docs.first;
      final referrerUid = brokerDoc.id;

      // Prevent self-referral.
      if (referrerUid == newUser.uid) return;

      // 2. Optionally look up listing details for the lead card.
      String? listingCity;
      String? listingPrice;
      if (pending.listingId != null) {
        final listingSnap = await _db
            .collection('listings')
            .doc(pending.listingId)
            .get();
        if (listingSnap.exists) {
          final d = listingSnap.data() ?? {};
          listingCity = d['city'] as String?;
          final price = (d['price'] as num?)?.toDouble();
          if (price != null) {
            if (price >= 10000000) {
              listingPrice = '₹${(price / 10000000).toStringAsFixed(2)} Cr';
            } else if (price >= 100000) {
              listingPrice = '₹${(price / 100000).toStringAsFixed(2)} L';
            } else {
              listingPrice = '₹${price.toStringAsFixed(0)}';
            }
          }
        }
      }

      // 3. Create the CRM lead for the referring broker.
      final leadId = _db.collection('leads').doc().id;
      final now = DateTime.now();
      await _db.collection('leads').doc(leadId).set({
        'id': leadId,
        'ownerUid': referrerUid,
        'clientName': newUser.name.isNotEmpty ? newUser.name : 'New User',
        'clientPhone': newUser.mobile,
        'stage': LeadStage.newLead.firestoreKey,
        'priority': LeadPriority.high.name,
        'estimatedValue': null,
        'linkedListingId': pending.listingId,
        'linkedListingCity': listingCity,
        'linkedListingPrice': listingPrice,
        'notes': <Map<String, dynamic>>[
          {
            'id': _db.collection('_').doc().id,
            'text': 'Auto-created from referral link shared by broker.',
            'createdAt': now.toIso8601String(),
          },
        ],
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('[Referral] lead $leadId created for broker $referrerUid');
      }

      // 4. Clear the pending referral so it isn't processed again.
      ref.read(pendingReferralProvider.notifier).state = null;
    } catch (e) {
      if (kDebugMode) debugPrint('[Referral] error: $e');
    }
  }
}
