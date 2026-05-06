import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/l10n/locale_provider.dart';
import 'package:cpapp/core/router/app_router.dart';
import 'package:cpapp/core/services/deep_link_service.dart';
import 'package:cpapp/core/services/fcm_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:cpapp/core/services/firebase_service.dart';
import 'package:cpapp/core/services/analytics_service.dart';
import 'package:cpapp/core/services/referral_service.dart';
import 'package:cpapp/core/theme/app_theme.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cap Flutter's in-memory image cache: 80 MB / 200 images max.
  // Default is unlimited — on a feed with many cards this causes OOM kills.
  PaintingBinding.instance.imageCache
    ..maximumSizeBytes = 80 * 1024 * 1024
    ..maximumSize = 200;

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar with dark icons on light backgrounds
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialise Firebase
  await FirebaseService.init();

  // Initialise timezone database (required for zonedSchedule local notifications)
  tz.initializeTimeZones();

  // Initialise FCM (channel, local notifications, background handler)
  await FcmService.init();

  runApp(
    // ProviderScope enables Riverpod throughout the widget tree
    const ProviderScope(
      child: CPApp(),
    ),
  );
}

/// Root application widget.
class CPApp extends ConsumerWidget {
  const CPApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Request FCM permission and save token once the user is authenticated.
    // Also fire referral lead creation when a new user completes their profile.
    ref.listen(authStateChangesProvider, (prev, next) {
      final uid = next.valueOrNull?.uid;
      if (uid != null) {
        FcmService.setupForUser(uid);
        AnalyticsService.logAppOpen(uid);
      }

      // Detect the moment isProfileComplete flips false → true.
      final wasComplete = prev?.valueOrNull?.isProfileComplete ?? false;
      final nowComplete = next.valueOrNull?.isProfileComplete ?? false;
      if (!wasComplete && nowComplete) {
        ReferralService.processIfPending(
          ref: ref,
          newUser: next.valueOrNull!,
        );
      }
    });

    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    // Forward every incoming deep link to the handler.
    ref.listen(deepLinkUriProvider, (_, next) {
      next.whenData((uri) => DeepLinkService.handle(uri, ref));
    });

    // ScreenUtil initialises the responsive sizing system.
    // Design canvas: 390×844 (iPhone 14 baseline).
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'CPApp',
          debugShowCheckedModeBanner: false,

          // Localisation
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Theme
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,

          // Router
          routerConfig: router,

          // Global scaffold messenger key for snackbars
          scaffoldMessengerKey: _scaffoldMessengerKey,

          // Builder ensures MediaQuery text scale is capped
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.2,
                ),
              ),
              child: child!,
            );
          },
        );
      },
    );
  }
}

/// Global scaffold messenger key for showing snackbars outside BuildContext.
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Helper to show a snackbar from anywhere in the app.
void showAppSnack(String message, {bool isError = false}) {
  _scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.navyDark,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
