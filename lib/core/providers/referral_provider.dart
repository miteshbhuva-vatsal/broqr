import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Data captured from an incoming deep link before the new user has registered.
/// Cleared automatically once [ReferralService] creates the CRM lead.
class PendingReferral {
  const PendingReferral({
    required this.referralCode,
    this.listingId,
    this.brokerId,
  });

  /// The 8-char code belonging to the broker who shared the link.
  final String referralCode;

  /// Set when the link pointed to a specific listing (cpapp://listing/{id}).
  final String? listingId;

  /// Set when the link pointed to a broker profile (cpapp://broker/{id}).
  final String? brokerId;

  @override
  String toString() =>
      'PendingReferral(code: $referralCode, listing: $listingId, broker: $brokerId)';
}

/// Holds the referral captured from an incoming deep link.
/// Watched by [ReferralService] to fire the CRM lead creation
/// as soon as the new user completes their profile.
final pendingReferralProvider = StateProvider<PendingReferral?>((ref) => null);
