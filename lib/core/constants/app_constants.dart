import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// App-wide string constants, limits, and config values.
abstract final class AppConstants {
  // ── App meta ──────────────────────────────────────────────────────────────
  static const String appName = 'DigiProp';
  static const String appTagline = 'Where Brokers Close Deals Faster';

  // ── Firestore collections ─────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';
  static const String leadsCollection = 'leads';
  static const String notificationsCollection = 'notifications';
  static const String connectionsCollection = 'connections';
  static const String chatsCollection = 'chats';
  static const String likesCollection = 'likes';
  static const String commentsCollection = 'comments';
  static const String viewsCollection = 'views';
  static const String postsCollection = 'posts';
  static const String localitiesCollection = 'localities';

  // ── Organisation / multi-tenant CRM ──────────────────────────────────────
  static const String organisationsCollection = 'organisations';
  static const String orgMembersCollection = 'org_members';
  static const String orgTeamsCollection = 'org_teams';
  static const String orgInvitesCollection = 'org_invites';
  static const String teamMembersSubcollection = 'team_members';
  static const String leadActivitySubcollection = 'activity';

  // ── Storage paths ─────────────────────────────────────────────────────────
  static const String profileImagesPath = 'profile_images';
  static const String listingImagesPath = 'listing_images';
  static const String postersPath = 'posters';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int feedPageSize = 10;
  static const int brokersPageSize = 20;
  static const int leadsPageSize = 20;

  // ── Listing limits ────────────────────────────────────────────────────────
  static const int maxListingImages = 10;
  static const int maxListingTitleLength = 80;
  static const int maxListingDescLength = 500;

  // ── Lead / CRM ────────────────────────────────────────────────────────────
  static const int maxNoteLength = 1000;

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const int maxMessageLength = 4000;

  // ── Deep links ────────────────────────────────────────────────────────────
  static const int maxReferralCodeLength = 32;
  static const String webDomain = 'www.digiprop.co.in';

  // ── Search ────────────────────────────────────────────────────────────────
  static const Duration searchDebounceDelay = Duration(milliseconds: 300);

  // ── Image ─────────────────────────────────────────────────────────────────
  static const int imageQuality = 85;
  static const double maxImageWidth = 1080;

  // ── Animation durations ───────────────────────────────────────────────────
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ── Snackbar ──────────────────────────────────────────────────────────────
  static const Duration snackbarDuration = Duration(seconds: 3);

  // ── Share ─────────────────────────────────────────────────────────────────
  static const String shareTextTemplate =
      '🏠 Check out this property deal on DigiProp!\n\n'
      '{title}\n{location}\n₹{price}\n\n'
      'Download DigiProp: https://www.digiprop.co.in';

  // ── Backend API (Next.js admin panel) ────────────────────────────────────
  // Web debug builds hit the locally-running admin so CORS + TEST_OTP_BYPASS
  // work without redeploying. Mobile and release web hit production.
  static String get apiBaseUrl => (kIsWeb && kDebugMode)
      ? 'http://localhost:3001'
      : 'https://cpapp-admin-ouzg8.ondigitalocean.app';
}
