import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/auth/presentation/screens/splash_screen.dart';
import 'package:cpapp/features/auth/presentation/screens/login_screen.dart';
import 'package:cpapp/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cpapp/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:cpapp/shared/widgets/shell_scaffold.dart';
import 'package:cpapp/features/feed/presentation/screens/feed_screen.dart';
import 'package:cpapp/features/crm/presentation/screens/crm_screen.dart';
import 'package:cpapp/features/broker_network/presentation/screens/network_screen.dart';
import 'package:cpapp/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:cpapp/features/profile/presentation/screens/profile_screen.dart';
import 'package:cpapp/features/listing/presentation/screens/add_listing_screen.dart';
import 'package:cpapp/features/listing/presentation/screens/listing_detail_screen.dart';
import 'package:cpapp/features/listing/presentation/screens/my_listings_screen.dart';
import 'package:cpapp/features/crm/presentation/screens/lead_detail_screen.dart';
import 'package:cpapp/features/broker_network/presentation/screens/broker_profile_screen.dart';
import 'package:cpapp/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:cpapp/features/chat/presentation/screens/chat_detail_screen.dart';
import 'package:cpapp/features/crm/presentation/screens/reminders_screen.dart';
import 'package:cpapp/features/news/presentation/screens/news_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:cpapp/dev/seed_screen.dart';

part 'app_router.g.dart';

/// Set to true by ProfileSetupScreen on successful save so the router
/// allows navigation to /feed even before the auth stream re-emits.
final profileCompleteOverrideProvider = StateProvider<bool>((_) => false);

/// Top-level navigator key — used by overlay widgets.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator key — keeps bottom nav alive while switching tabs.
final shellNavigatorKey = GlobalKey<NavigatorState>();

/// Routes accessible without authentication.
const _publicRoutes = {
  Routes.splash,
  Routes.onboarding,
  Routes.login,
};

@riverpod
GoRouter appRouter(Ref ref) {
  // Watching this stream causes GoRouter to re-evaluate the redirect
  // whenever the auth state changes (sign-in, sign-out, profile updated).
  final authState = ref.watch(authStateChangesProvider);
  final profileCompleteOverride = ref.watch(profileCompleteOverrideProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,

    // ── Auth redirect guard ──────────────────────────────────────────────────
    redirect: (context, routerState) {
      final location = routerState.uri.toString();
      final isPublic =
          _publicRoutes.contains(location) || location == Routes.profileSetup;

      // While Firebase is resolving the auth state, stay on splash
      if (authState.isLoading) {
        return location == Routes.splash ? null : Routes.splash;
      }

      final user = authState.valueOrNull;

      // Not signed in → redirect to onboarding unless already on a public route
      if (user == null) {
        return isPublic ? null : Routes.onboarding;
      }

      // Signed in but profile incomplete → profile setup
      // profileCompleteOverride is set true by ProfileSetupScreen on successful
      // save so we don't bounce back before the auth stream re-emits.
      final isComplete = user.isProfileComplete || profileCompleteOverride;
      if (!isComplete && location != Routes.profileSetup) {
        return Routes.profileSetup;
      }

      // Signed in + complete → don't stay on auth/onboarding screens
      if (isComplete &&
          (location == Routes.splash ||
              location == Routes.onboarding ||
              location == Routes.login ||
              location == Routes.profileSetup)) {
        return Routes.feed;
      }

      return null; // no redirect needed
    },

    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Onboarding ───────────────────────────────────────────────────────
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

      GoRoute(
        path: Routes.profileSetup,
        name: 'profileSetup',
        builder: (_, __) => const ProfileSetupScreen(),
      ),

      // ── Add Listing (full-screen, outside shell) ────────────────────────
      GoRoute(
        path: Routes.addListing,
        name: 'addListing',
        builder: (_, __) => const AddListingScreen(),
      ),

      // ── Listing detail (full-screen, outside shell) ───────────────────
      GoRoute(
        path: Routes.listingDetail,
        name: 'listingDetail',
        builder: (_, state) => ListingDetailScreen(
          listingId: state.pathParameters['listingId']!,
        ),
      ),

      // ── Lead detail (full-screen, outside shell) ─────────────────────
      GoRoute(
        path: Routes.leadDetail,
        name: 'leadDetail',
        builder: (_, state) => LeadDetailScreen(
          leadId: state.pathParameters['leadId']!,
        ),
      ),

      // ── Broker profile (full-screen, outside shell) ───────────────────
      GoRoute(
        path: Routes.brokerProfile,
        name: 'brokerProfile',
        builder: (_, state) => BrokerProfileScreen(
          brokerId: state.pathParameters['brokerId']!,
        ),
      ),

      // ── Profile (full-screen, outside shell) ─────────────────────────
      GoRoute(
        path: Routes.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),

      // ── My Listings (full-screen, outside shell) ──────────────────────
      GoRoute(
        path: Routes.myListings,
        name: 'myListings',
        builder: (_, __) => const MyListingsScreen(),
      ),

      // ── Notifications (full-screen, outside shell) ────────────────────
      GoRoute(
        path: Routes.notifications,
        name: 'notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Chat list (full-screen, outside shell) ────────────────────────
      GoRoute(
        path: Routes.chat,
        name: 'chat',
        builder: (_, __) => const ChatListScreen(),
      ),

      // ── Chat detail (full-screen, outside shell) ──────────────────────
      GoRoute(
        path: Routes.chatDetail,
        name: 'chatDetail',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatDetailScreen(
            chatId: state.pathParameters['chatId']!,
            otherName: extra['otherName'] as String? ?? 'Chat',
            otherPhoto: extra['otherPhoto'] as String?,
          );
        },
      ),

      // ── Dev seed (debug builds only) ─────────────────────────────────────
      if (kDebugMode)
        GoRoute(
          path: Routes.devSeed,
          name: 'devSeed',
          builder: (_, __) => const SeedScreen(),
        ),

      // ── Network (full-screen, accessible from profile) ───────────────────
      GoRoute(
        path: Routes.network,
        name: 'network',
        builder: (_, __) => const NetworkScreen(),
      ),

      // ── Main shell (bottom nav) ──────────────────────────────────────────
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.feed,
            name: 'feed',
            builder: (_, __) => const FeedScreen(),
          ),
          GoRoute(
            path: Routes.news,
            name: 'news',
            builder: (_, __) => const NewsScreen(),
          ),
          GoRoute(
            path: Routes.reminders,
            name: 'reminders',
            builder: (_, __) => const RemindersScreen(),
          ),
          GoRoute(
            path: Routes.crm,
            name: 'crm',
            builder: (_, __) => const CrmScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
