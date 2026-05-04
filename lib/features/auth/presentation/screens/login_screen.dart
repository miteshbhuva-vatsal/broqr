import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/shared/widgets/app_button.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

/// Login screen — Google + Facebook sign-in.
/// Listens to [authProvider] and routes on success.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen for auth state changes to drive navigation
    ref.listen<AuthState>(authProvider, (_, next) {
      switch (next) {
        case AuthStateAuthenticated(:final user):
          if (user.isProfileComplete) {
            context.go(Routes.feed);
          } else {
            context.go(Routes.profileSetup);
          }
        case AuthStateError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(authProvider.notifier).clearError();
        default:
          break;
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Back button
                  IconButton(
                    onPressed: () => context.go(Routes.onboarding),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white, size: 20,),
                    padding: EdgeInsets.zero,
                  ),

                  const Spacer(),

                  // Logo + headline
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.home_work_outlined,
                              color: AppColors.navyDark, size: 38,),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome to CPApp',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to access exclusive broker deals',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textOnDarkSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Social auth buttons
                  _SocialDivider(),
                  const SizedBox(height: 20),

                  // Google
                  SocialAuthButton(
                    label: 'Continue with Google',
                    icon: _GoogleIcon(),
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).signInWithGoogle(),
                  ),

                  const SizedBox(height: 12),

                  // Facebook
                  SocialAuthButton(
                    label: 'Continue with Facebook',
                    icon: _FacebookIcon(),
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () => ref.read(authProvider.notifier).signInWithFacebook(),
                  ),

                  // Debug-only anonymous sign-in
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => ref
                              .read(authProvider.notifier)
                              .signInAnonymously(),
                      child: const Text(
                        '⚙ Debug: Skip Auth',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Terms
                  Center(
                    child: Text(
                      'By continuing you agree to our Terms of Service\nand Privacy Policy.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _SocialDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderDark, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Sign in with',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textOnDarkSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderDark, thickness: 1)),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Inline SVG-style Google "G" logo using a styled container
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
