import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

/// Splash screen — listens to auth state then routes accordingly.
/// • Signed in + profile complete   → Feed
/// • Signed in + profile incomplete → Profile Setup
/// • Not signed in                  → Onboarding
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Give Firebase time to emit its first auth state, then route.
    Future.delayed(const Duration(milliseconds: 1800), _handleNavigation);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleNavigation() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final authState = ref.read(authStateChangesProvider);

    authState.when(
      data: (user) {
        if (user == null) {
          context.go(Routes.onboarding);
        } else if (!user.isProfileComplete) {
          context.go(Routes.profileSetup);
        } else {
          context.go(Routes.feed);
        }
      },
      loading: () => context.go(Routes.onboarding),
      error: (_, __) => context.go(Routes.onboarding),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App logo
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_work_outlined,
                  color: AppColors.navyDark,
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'CPApp',
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Where Brokers Close Deals Faster',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.gold.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
