import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/providers/referral_provider.dart';
import 'package:cpapp/core/router/app_router.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/foundation.dart';

// ── Stream provider — surfaces every incoming deep-link URI ───────────────────

/// Emits every URI received via cpapp:// (custom scheme) or
/// https://www.digiprop.co.in (App Links / Universal Links).
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
  // Firestore document IDs are base64url-ish but UUIDs use hex + hyphens;
  // allow alphanum, hyphens and underscores up to 128 chars.
  static final _idRe = RegExp(r'^[a-zA-Z0-9_\-]{1,128}$');
  static final _codeRe = RegExp(r'^[a-zA-Z0-9_\-]{1,32}$');

  static bool _validId(String? s) => s != null && _idRe.hasMatch(s);
  static String? _sanitiseCode(String? s) =>
      (s != null && _codeRe.hasMatch(s)) ? s : null;

  // ── Handle ──────────────────────────────────────────────────────────────

  // Both old and new domains are accepted so previously shared links keep working.
  static const _legacyDomain = 'www.digiprop.in';

  /// Call this from the root widget whenever [deepLinkUriProvider] emits.
  /// Handles both:
  ///   cpapp://listing/{id}?ref={code}               — custom scheme (legacy)
  ///   https://www.digiprop.co.in/listing/{id}?ref={code} — App/Universal Links
  static void handle(Uri uri, WidgetRef ref) {
    if (kDebugMode) debugPrint('[DeepLink] incoming: $uri');

    // Normalise: extract resource type + id regardless of scheme.
    final String? resource;
    final String? resourceId;

    if (uri.scheme == 'cpapp') {
      // cpapp://listing/{id}  →  host = resource, first path segment = id
      resource = uri.host;
      resourceId = uri.pathSegments.firstOrNull;
    } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        (uri.host == AppConstants.webDomain || uri.host == _legacyDomain) &&
        uri.pathSegments.length >= 2) {
      // https://www.digiprop.co.in/listing/{id}  →  path[0] = resource, path[1] = id
      resource = uri.pathSegments[0];
      resourceId = uri.pathSegments[1];
    } else {
      return; // unrecognised link — ignore
    }

    final code = _sanitiseCode(uri.queryParameters['ref']);
    final router = ref.read(appRouterProvider);

    switch (resource) {
      case 'listing':
        if (!_validId(resourceId)) return;
        if (code != null) {
          ref.read(pendingReferralProvider.notifier).state =
              PendingReferral(referralCode: code, listingId: resourceId!);
        }
        router.push(
          Routes.listingDetail.replaceFirst(':listingId', resourceId!),
        );

      case 'broker':
        if (!_validId(resourceId)) return;
        if (code != null) {
          ref.read(pendingReferralProvider.notifier).state =
              PendingReferral(referralCode: code, brokerId: resourceId!);
        }
        final myUid =
            ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
        if (resourceId == myUid) {
          router.push(Routes.profile);
        } else {
          router.push(
            Routes.realtorProfile.replaceFirst(':realtorId', resourceId!),
          );
        }

      case 'post':
        // No dedicated post detail screen — open the Ask tab.
        router.go(Routes.ask);
    }
  }

  // ── Generate ─────────────────────────────────────────────────────────────

  /// Shareable HTTPS link for a listing — opens in-app via Universal/App Links
  /// or falls back gracefully in a browser.
  static Uri listingUri(String listingId, String referralCode) => Uri(
        scheme: 'https',
        host: AppConstants.webDomain,
        pathSegments: ['listing', listingId],
        queryParameters: {'ref': referralCode},
      );

  /// Shareable HTTPS link for a broker profile.
  static Uri brokerUri(String brokerId, String referralCode) => Uri(
        scheme: 'https',
        host: AppConstants.webDomain,
        pathSegments: ['broker', brokerId],
        queryParameters: {'ref': referralCode},
      );

  /// Shareable HTTPS link for an Ask community post.
  static Uri postUri(String postId) => Uri(
        scheme: 'https',
        host: AppConstants.webDomain,
        pathSegments: ['post', postId],
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
        'Shared by $brokerName via DigiProp\n'
        '🔗 $link\n'
        '\n'
        '📲 Download DigiProp: https://${AppConstants.webDomain}';
  }

  static String brokerShareText({
    required String brokerName,
    required String? city,
    required String brokerId,
    required String referralCode,
  }) {
    final link = brokerUri(brokerId, referralCode);
    final cityPart = city != null ? ' · $city' : '';
    return '👤 Connect with $brokerName$cityPart on DigiProp!\n'
        '\n'
        '🔗 $link\n'
        '\n'
        '📲 Download DigiProp: https://${AppConstants.webDomain}';
  }

  static String postShareText({
    required String authorName,
    required String bodyPreview,
    required String postId,
  }) {
    final link = postUri(postId);
    final preview = bodyPreview.length > 80
        ? '${bodyPreview.substring(0, 80)}…'
        : bodyPreview;
    return '💬 $authorName on DigiProp:\n'
        '"$preview"\n'
        '\n'
        '🔗 $link\n'
        '\n'
        '📲 Download DigiProp: https://${AppConstants.webDomain}';
  }
}
