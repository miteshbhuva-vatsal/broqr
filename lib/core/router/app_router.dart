import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/providers/navigation_overrides.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/auth/presentation/screens/splash_screen.dart';
import 'package:cpapp/features/auth/presentation/screens/login_screen.dart';
import 'package:cpapp/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cpapp/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:cpapp/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:cpapp/features/settings/presentation/screens/language_screen.dart';
import 'package:cpapp/shared/widgets/shell_scaffold.dart';
import 'package:cpapp/features/feed/presentation/screens/feed_screen.dart';
import 'package:cpapp/features/crm/presentation/screens/crm_screen.dart';
import 'package:cpapp/features/realtors/presentation/screens/realtor_profile_screen.dart';
import 'package:cpapp/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cpapp/features/profile/presentation/screens/profile_screen.dart';
import 'package:cpapp/features/listing/presentation/screens/add_listing_screen.dart';
import 'package:cpapp/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:cpapp/features/listing/presentation/screens/my_listings_screen.dart';
import 'package:cpapp/features/crm/presentation/screens/lead_detail_screen.dart';
import 'package:cpapp/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:cpapp/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:cpapp/features/crm/presentation/screens/reminders_screen.dart';
import 'package:cpapp/features/ask/presentation/screens/ask_screen.dart';
import 'package:cpapp/features/realtors/presentation/screens/realtors_screen.dart';
import 'package:cpapp/features/crm/presentation/screens/subscription_plan_screen.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_screen.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/onboarding/presentation/screens/persona_selection_screen.dart';
import 'package:cpapp/features/onboarding/presentation/screens/buyer_onboarding_screen.dart';
import 'package:cpapp/features/onboarding/presentation/screens/seller_onboarding_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:cpapp/dev/seed_screen.dart';

part 'app_router.g.dart';

/// Top-level navigator key — used by overlay widgets.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator key — kept for backward-compat references.
final shellNavigatorKey = GlobalKey<NavigatorState>();

// Per-branch navigator keys for StatefulShellRoute.
final _feedNavKey     = GlobalKey<NavigatorState>(debugLabel: 'feedNav');
final _crmNavKey      = GlobalKey<NavigatorState>(debugLabel: 'crmNav');
final _askNavKey      = GlobalKey<NavigatorState>(debugLabel: 'askNav');
final _realtorsNavKey = GlobalKey<NavigatorState>(debugLabel: 'realtorsNav');

/// Routes accessible without authentication.
const _publicRoutes = {
  Routes.splash,
  Routes.onboarding,
  Routes.login,
};

/// Post-login setup routes the guard must never bounce away from.
const _authOnlyRoutes = {
  Routes.profileSetup,
  Routes.personaSelection,
  Routes.buyerOnboarding,
  Routes.sellerOnboarding,
};

/// Notifies GoRouter to re-run its redirect without recreating the router.
class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Queries Firestore for a pending org invite matching the user's mobile.
/// Stores the invite document in [pendingOrgInviteProvider] if one is found.
Future<void> _checkAndSetInvite(Ref ref, AppUser user) async {
  var mobile = user.mobile ?? '';
  if (mobile.isEmpty) {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    if (phone.startsWith('+91') && phone.length == 13) mobile = phone.substring(3);
  }
  if (mobile.isEmpty) return;
  try {
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.orgInvitesCollection)
        .where('mobile', isEqualTo: mobile)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get()
        .timeout(const Duration(seconds: 5));
    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      if ((data['orgId'] as String?)?.isNotEmpty == true) {
        ref.read(pendingOrgInviteProvider.notifier).state = data;
      }
    }
  } catch (_) {}
}

@riverpod
GoRouter appRouter(Ref ref) {
  // ── Refresh notifier ────────────────────────────────────────────────────────
  // GoRouter is created ONCE. Instead of ref.watch (which would recreate the
  // GoRouter on every auth change, flashing initialLocation=splash before
  // redirect fires), we use ref.listen + refreshListenable.
  // GoRouter calls redirect() on each notify() without rebuilding the router.
  final notifier = _RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);

  // Auth state changes → refresh router + side-effects.
  ref.listen(authStateChangesProvider, (previous, next) {
    final prevUser = previous?.valueOrNull;
    final nextUser = next.valueOrNull;

    // Reset override flags when user signs out or a different user signs in.
    // Without this, a previous user's completed-profile override leaks into
    // the new user's session and bypasses persona/profile-setup routing.
    if (prevUser != null && (nextUser == null || nextUser.uid != prevUser.uid)) {
      ref.read(profileCompleteOverrideProvider.notifier).state = false;
      ref.read(onboardingCompleteOverrideProvider.notifier).state = false;
      ref.read(pendingOrgInviteProvider.notifier).state = null;
      ref.read(crmSetupDoneProvider.notifier).state = false;
    }

    // Sync currentOrgId when auth resolves.
    final user = nextUser;
    final currentOrgId = ref.read(currentOrgIdProvider);
    if (user?.orgId != null && currentOrgId != user!.orgId) {
      ref.read(currentOrgIdProvider.notifier).state = user.orgId;
    } else if (user != null && user.orgId == null && currentOrgId != null) {
      ref.read(currentOrgIdProvider.notifier).state = null;
    }

    // For new users with no persona: check for a pending org invite.
    // If found, pendingOrgInviteProvider is set → redirect will skip
    // persona selection and send the user straight to profile setup.
    if (!next.isLoading &&
        user != null &&
        !user.isProfileComplete &&
        !user.hasPersona &&
        user.orgId == null &&
        ref.read(pendingOrgInviteProvider) == null) {
      final mobileAuthPending = ref.read(mobileAuthFlowPendingProvider);
      _checkAndSetInvite(ref, user).then((_) {
        // Clear mobileAuthPending here (instead of below) so routing only
        // fires after the invite check — no flash of persona selection.
        if (mobileAuthPending) {
          ref.read(mobileAuthFlowPendingProvider.notifier).state = false;
        }
        notifier.notify();
      });
      if (mobileAuthPending) {
        // Keep the auth-flow window open while invite check runs.
        notifier.notify(); // router sees mobileAuthPending=true → stays put
        return;
      }
      // Returning user (no active OTP flow): fall through and notify now;
      // the router will re-evaluate when _checkAndSetInvite resolves.
    }

    // Clear mobileAuthPending once auth resolves after OTP sign-in.
    // Doing it here (not in sheet dispose) ensures the flag stays true
    // until Firestore asyncMap completes — no window for a splash flash.
    if (!next.isLoading && ref.read(mobileAuthFlowPendingProvider)) {
      Future.microtask(
        () => ref.read(mobileAuthFlowPendingProvider.notifier).state = false,
      );
    }
    notifier.notify();
  });

  // Override flags → refresh router so redirect re-evaluates immediately.
  ref.listen(mobileAuthFlowPendingProvider,      (_, __) => notifier.notify());
  ref.listen(profileCompleteOverrideProvider,    (_, __) => notifier.notify());
  ref.listen(onboardingCompleteOverrideProvider, (_, __) => notifier.notify());
  ref.listen(pendingOrgInviteProvider,           (_, __) => notifier.notify());
  ref.listen(crmSetupDoneProvider,               (_, __) => notifier.notify());

  // ── Router (created once, lives for the lifetime of the provider) ───────────
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: true,

    redirect: (context, routerState) {
      final location = routerState.uri.toString();

      // Read current values — never watch inside redirect.
      final authState           = ref.read(authStateChangesProvider);
      final mobileAuthPending   = ref.read(mobileAuthFlowPendingProvider);
      final profileOverride     = ref.read(profileCompleteOverrideProvider);
      final onboardingOverride  = ref.read(onboardingCompleteOverrideProvider);

      final isPublic   = _publicRoutes.contains(location);
      final isAuthOnly = _authOnlyRoutes.contains(location);

      // Freeze ALL routing while OTP post-auth flow is in progress.
      // Checked first so no intermediate screen appears mid-flow.
      if (mobileAuthPending) return null;

      // While Firebase is resolving auth state → splash.
      if (authState.isLoading) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final user = authState.valueOrNull;

      // Not signed in → onboarding.
      if (user == null) {
        return isPublic ? null : Routes.onboarding;
      }

      final isComplete = user.isProfileComplete || profileOverride;

      // New user, no persona → persona selection (unless they have a pending invite).
      if (!isComplete && !user.hasPersona && user.orgId == null) {
        final pendingInvite = ref.read(pendingOrgInviteProvider);
        if (pendingInvite != null) {
          return location == Routes.profileSetup ? null : Routes.profileSetup;
        }
        return location == Routes.personaSelection ? null : Routes.personaSelection;
      }

      // Has persona but profile incomplete → profile setup.
      if (!isComplete && location != Routes.profileSetup) {
        return Routes.profileSetup;
      }

      // Buyer, onboarding not done → buyer onboarding.
      if (isComplete && user.isBuyer && !user.hasCompletedOnboarding && !onboardingOverride) {
        return location == Routes.buyerOnboarding ? null : Routes.buyerOnboarding;
      }

      // Seller, onboarding not done → seller onboarding.
      if (isComplete && user.isSeller && !user.hasCompletedOnboarding && !onboardingOverride) {
        return location == Routes.sellerOnboarding ? null : Routes.sellerOnboarding;
      }

      // CRM subscription gate — sellers must complete plan setup before entering CRM.
      if (isComplete && location == Routes.crm) {
        final crmSetupDone = ref.read(crmSetupDoneProvider);
        final sessionOrgId = ref.read(currentOrgIdProvider);
        final hasPendingInvite = ref.read(pendingOrgInviteProvider) != null;
        final isOrgMember =
            user.orgId != null || sessionOrgId != null || hasPendingInvite;
        if (user.isSeller &&
            !user.hasConfirmedAccountType &&
            !isOrgMember &&
            !crmSetupDone) {
          return Routes.subscriptionPlan;
        }
      }

      // Signed in + complete → leave public/auth-only/splash screens.
      if (isComplete && (isPublic || isAuthOnly || location == Routes.splash)) {
        return Routes.feed;
      }

      return null;
    },

    routes: [
      GoRoute(path: Routes.splash,        name: 'splash',        builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.onboarding,    name: 'onboarding',    builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.login,         name: 'login',         builder: (_, __) => const LoginScreen()),
      GoRoute(path: Routes.profileSetup,  name: 'profileSetup',  builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: Routes.personaSelection, name: 'personaSelection', builder: (_, __) => const PersonaSelectionScreen()),
      GoRoute(path: Routes.buyerOnboarding,  name: 'buyerOnboarding',  builder: (_, __) => const BuyerOnboardingScreen()),
      GoRoute(path: Routes.sellerOnboarding, name: 'sellerOnboarding', builder: (_, __) => const SellerOnboardingScreen()),
      GoRoute(path: Routes.subscriptionPlan, name: 'subscriptionPlan', builder: (_, __) => const SubscriptionPlanScreen()),
      GoRoute(path: Routes.addListing,    name: 'addListing',    builder: (_, __) => const AddListingScreen()),
      GoRoute(
        path: Routes.listingDetail,
        name: 'listingDetail',
        builder: (_, state) => ListingDetailScreen(listingId: state.pathParameters['listingId']!),
      ),
      GoRoute(
        path: Routes.leadDetail,
        name: 'leadDetail',
        builder: (_, state) => LeadDetailScreen(leadId: state.pathParameters['leadId']!),
      ),
      GoRoute(
        path: Routes.realtorProfile,
        name: 'realtorProfile',
        builder: (_, state) => RealtorProfileScreen(realtorId: state.pathParameters['realtorId']!),
      ),
      GoRoute(path: Routes.profile,       name: 'profile',       builder: (_, __) => const ProfileScreen()),
      GoRoute(path: Routes.editProfile,   name: 'editProfile',   builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: Routes.language,      name: 'language',      builder: (_, __) => const LanguageScreen()),
      GoRoute(path: Routes.myListings,    name: 'myListings',    builder: (_, __) => const MyListingsScreen()),
      GoRoute(path: Routes.notifications, name: 'notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: Routes.chat,          name: 'chat',          builder: (_, __) => const ChatListScreen()),
      GoRoute(
        path: Routes.chatDetail,
        name: 'chatDetail',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatDetailScreen(
            chatId:     state.pathParameters['chatId']!,
            otherName:  extra['otherName']  as String? ?? 'Chat',
            otherPhoto: extra['otherPhoto'] as String?,
            otherUid:   extra['otherUid']   as String?,
          );
        },
      ),
      if (kDebugMode)
        GoRoute(path: Routes.devSeed, name: 'devSeed', builder: (_, __) => const SeedScreen()),

      // ── Main shell (bottom nav) ─────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _feedNavKey,
            routes: [GoRoute(path: Routes.feed, name: 'feed', builder: (_, __) => const FeedScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _crmNavKey,
            routes: [
              GoRoute(path: Routes.crm,          name: 'crm',          builder: (_, __) => const CrmScreen()),
              GoRoute(path: Routes.reminders,    name: 'reminders',    builder: (_, __) => const RemindersScreen()),
              GoRoute(path: Routes.organisation, name: 'organisation', builder: (_, __) => const OrgScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _askNavKey,
            routes: [GoRoute(path: Routes.ask, name: 'ask', builder: (_, __) => const AskScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _realtorsNavKey,
            routes: [GoRoute(path: Routes.realtors, name: 'realtors', builder: (_, __) => const RealtorsScreen())],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
}
