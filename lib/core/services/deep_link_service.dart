import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/providers/referral_provider.dart';
import 'package:cpapp/core/router/app_router.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';

// ── Stream provider — surfaces every incoming deep-link URI ───────────────────

/// Emits every URI received via the cpapp:// custom scheme.
/// The initial link (app cold-started from a link) is emitted first.
final deepLinkUriProvider = StreamProvider<Uri>((ref) async* {
  final appLinks = AppLinks();

  // Cold-start: app was completely closed when the link was tapped.
  final initial = await appLinks.getInitialLink();
  if (initial != null) yield initial;

  // Warm/hot-start: app already running or resumed from background.
  yield* appLinks.uriLinkStream;
});

// ── Service — URI parsing + link generation ───────────────────────────────────

abstract final class DeepLinkService {
  // ── Handle ──────────────────────────────────────────────────────────────

  /// Call this from the root widget whenever [deepLinkUriProvider] emits.
  /// Stores referral context and navigates to the target screen.
  static void handle(Uri uri, WidgetRef ref) {
    if (uri.scheme != 'cpapp') return;
    if (kDebugMode) debugPrint('[DeepLink] incoming: $uri');

    final code = uri.queryParameters['ref'];
    final router = ref.read(appRouterProvider);

    switch (uri.host) {
      case 'listing':
        final listingId = uri.pathSegments.firstOrNull;
        if (listingId == null) return;
        if (code != null) {
          ref.read(pendingReferralProvider.notifier).state =
              PendingReferral(referralCode: code, listingId: listingId);
        }
        router.push(
          Routes.listingDetail.replaceFirst(':listingId', listingId),
        );

      case 'broker':
        final brokerId = uri.pathSegments.firstOrNull;
        if (brokerId == null) return;
        if (code != null) {
          ref.read(pendingReferralProvider.notifier).state =
              PendingReferral(referralCode: code, brokerId: brokerId);
        }
        final myUid =
            ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
        if (brokerId == myUid) {
          router.push(Routes.profile);
        } else {
          router.push(
            Routes.brokerProfile.replaceFirst(':brokerId', brokerId),
          );
        }
    }
  }

  // ── Generate ─────────────────────────────────────────────────────────────

  /// Deep link for a listing. Opens the listing detail when app is installed.
  static Uri listingUri(String listingId, String referralCode) => Uri(
        scheme: 'cpapp',
        host: 'listing',
        pathSegments: [listingId],
        queryParameters: {'ref': referralCode},
      );

  /// Deep link for a broker profile.
  static Uri brokerUri(String brokerId, String referralCode) => Uri(
        scheme: 'cpapp',
        host: 'broker',
        pathSegments: [brokerId],
        queryParameters: {'ref': referralCode},
      );

  // ── Share text builders ───────────────────────────────────────────────────

  static String listingShareText({
    required String emoji,
    required String category,
    required String location,
    required String city,
    required String price,
    required String area,
    required String brokerName,
    required String listingId,
    required String referralCode,
  }) {
    final link = listingUri(listingId, referralCode);
    return '$emoji $category Deal\n'
        '📍 $location, $city\n'
        '💰 $price  •  📐 $area\n'
        '\n'
        'Shared by $brokerName via CPApp\n'
        '🔗 $link\n'
        '\n'
        '📲 Download CPApp to connect with verified brokers';
  }

  static String brokerShareText({
    required String brokerName,
    required String? city,
    required String brokerId,
    required String referralCode,
  }) {
    final link = brokerUri(brokerId, referralCode);
    final cityPart = city != null ? ' · $city' : '';
    return '👤 Connect with $brokerName$cityPart on CPApp!\n'
        '\n'
        '🔗 $link\n'
        '\n'
        '📲 Download CPApp to grow your broker network';
  }
}
