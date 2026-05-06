/// Named route paths used throughout GoRouter.
/// Using a single source of truth prevents string mismatches.
abstract final class Routes {
  // ── Root ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/login';
  static const String profileSetup = '/profile-setup';

  // ── Main shell (bottom nav) ───────────────────────────────────────────────
  static const String shell = '/app';

  // ── Feed ──────────────────────────────────────────────────────────────────
  static const String feed = '/app/feed';
  static const String listingDetail = '/app/feed/listing/:listingId';

  // ── Listing ───────────────────────────────────────────────────────────────
  static const String addListing = '/app/add-listing';

  // ── CRM ───────────────────────────────────────────────────────────────────
  static const String crm = '/app/crm';
  static const String leadDetail = '/app/crm/lead/:leadId';

  // ── News ──────────────────────────────────────────────────────────────────
  static const String news = '/app/news';

  // ── Network ───────────────────────────────────────────────────────────────
  static const String network = '/app/network';
  static const String brokerProfile = '/app/network/broker/:brokerId';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String chat = '/app/chat';
  static const String chatDetail = '/app/chat/:chatId';

  // ── Reminders ─────────────────────────────────────────────────────────────
  static const String reminders = '/app/reminders';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/app/notifications';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String profile = '/app/profile';
  static const String editProfile = '/app/profile/edit';
  static const String myListings = '/app/profile/listings';

  // ── Search ────────────────────────────────────────────────────────────────
  static const String search = '/app/search';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String language = '/app/settings/language';

  // ── Dev (debug builds only) ───────────────────────────────────────────────
  static const String devSeed = '/dev/seed';
}
