/// App-wide string constants, limits, and config values.
abstract final class AppConstants {
  // ── App meta ──────────────────────────────────────────────────────────────
  static const String appName = 'CPApp';
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

  // ── Storage paths ─────────────────────────────────────────────────────────
  static const String profileImagesPath = 'profile_images';
  static const String listingImagesPath = 'listing_images';
  static const String postersPath = 'posters';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int feedPageSize = 10;
  static const int brokersPageSize = 20;
  static const int leadsPageSize = 20;

  // ── Listing limits ────────────────────────────────────────────────────────
  static const int maxListingImages = 5;
  static const int maxListingTitleLength = 80;
  static const int maxListingDescLength = 500;

  // ── Lead / CRM ────────────────────────────────────────────────────────────
  static const int maxNoteLength = 1000;

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
      '🏠 Check out this property deal on CPApp!\n\n'
      '{title}\n{location}\n₹{price}\n\n'
      'Download CPApp: https://cpapp.page.link/download';

  // ── Twilio ────────────────────────────────────────────────────────────────
  // Replace with actual values from environment / secrets
  static const String twilioVerifyBaseUrl =
      'https://verify.twilio.com/v2/Services';
}
