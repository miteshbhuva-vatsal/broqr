import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set to true by ProfileSetupScreen on successful save so the router
/// allows navigation to /feed even before the auth stream re-emits.
final profileCompleteOverrideProvider = StateProvider<bool>((_) => false);

/// Set to true by MobileLoginSheet while its post-auth flow is in progress.
/// Prevents the router from redirecting to /persona-selection before the
/// sheet is done, eliminating the one-second flash of that screen.
final mobileAuthFlowPendingProvider = StateProvider<bool>((_) => false);

/// Set to true by SellerOnboardingScreen / BuyerOnboardingScreen after the
/// user taps the final CTA. Prevents the router from redirecting back to the
/// onboarding screen while authStateChangesProvider is momentarily reloading.
final onboardingCompleteOverrideProvider = StateProvider<bool>((_) => false);

/// Populated by the router's auth listener when a newly-signed-in user has a
/// pending org invite. Lets the router skip persona selection and route
/// directly to profile setup, and lets ProfileSetupScreen pre-fill the form.
/// Cleared on sign-out / user change.
final pendingOrgInviteProvider = StateProvider<Map<String, dynamic>?>((_) => null);

/// Set to true by SubscriptionPlanScreen after the seller completes CRM setup.
/// Prevents _CrmGateway from re-appearing during the auth-stream race window.
/// Cleared on sign-out / user change.
final crmSetupDoneProvider = StateProvider<bool>((_) => false);
