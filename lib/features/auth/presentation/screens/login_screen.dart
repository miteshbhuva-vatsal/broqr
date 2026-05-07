import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/l10n/locale_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_notifier.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);

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

                  // Top row: back + language picker
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(Routes.onboarding),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const Spacer(),
                      _LanguagePicker(l: l),
                    ],
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
                          child: const Icon(
                            Icons.home_work_outlined,
                            color: AppColors.navyDark,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l.welcomeTitle,
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.welcomeSubtitle,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textOnDarkSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  _SocialDivider(label: l.signInWith),
                  const SizedBox(height: 20),

                  _SocialAuthButton(
                    label: l.continueWithGoogle,
                    icon: const _GoogleIcon(),
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () =>
                            ref.read(authProvider.notifier).signInWithGoogle(),
                  ),

                  const SizedBox(height: 12),

                  _SocialAuthButton(
                    label: l.continueWithFacebook,
                    icon: const _FacebookIcon(),
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () => ref
                            .read(authProvider.notifier)
                            .signInWithFacebook(),
                  ),

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

                  Center(
                    child: Text(
                      l.termsText,
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

// ── Language picker chip ───────────────────────────────────────────────────────

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    const labels = {'en': 'EN', 'hi': 'हिं', 'gu': 'ગુ'};
    final label = labels[current.languageCode] ?? 'EN';

    return GestureDetector(
      onTap: () => _showPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language_rounded,
              color: AppColors.gold,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final languages = [
      ('en', l.languageEnglish, '🇬🇧'),
      ('hi', l.languageHindi, '🇮🇳'),
      ('gu', l.languageGujarati, '🏛️'),
    ];
    final current = ref.read(localeProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.navyMid,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.chooseLanguage,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...languages.map((lang) {
              final (code, name, flag) = lang;
              final isSelected = current.languageCode == code;
              return GestureDetector(
                onTap: () async {
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(code));
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold.withValues(alpha: 0.15)
                        : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : AppColors.borderDark,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        flag,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.labelLarge.copyWith(
                            color:
                                isSelected ? AppColors.gold : AppColors.white,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.gold,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _SocialDivider extends StatelessWidget {
  const _SocialDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.borderDark, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textOnDarkSecondary),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.borderDark, thickness: 1),
        ),
      ],
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });
  final String label;
  final Widget icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : icon,
        label: Text(
          label,
          style: AppTypography.labelLarge.copyWith(color: AppColors.white),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
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
  const _FacebookIcon();
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
