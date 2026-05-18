import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

class SellerOnboardingScreen extends ConsumerWidget {
  const SellerOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authStateChangesProvider).valueOrNull;
    final city = ref.watch(cityPreferenceProvider) ?? user?.city ?? 'Your City';
    final isSaving = ref.watch(profileSetupProvider) is ProfileSetupSaving;

    ref.listen<ProfileSetupState>(profileSetupProvider, (_, next) {
      if (next is ProfileSetupSuccess) context.go(Routes.feed);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Step indicator ─────────────────────────────────────────
                Row(
                  children: List.generate(3, (i) {
                    final active = i == 2;
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.gold
                            : AppColors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // ── Headline ────────────────────────────────────────────────
                Text(
                  l.sellerWelcomeTo,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  city,
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                Text(
                  l.sellerPropertyMarket,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  l.sellerProfileReady,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Feature cards ───────────────────────────────────────────
                _FeatureCard(
                  icon: Icons.apartment_rounded,
                  title: l.sellerFeature1Title,
                  subtitle: l.sellerFeature1Sub,
                ),
                const SizedBox(height: 14),
                _FeatureCard(
                  icon: Icons.people_alt_rounded,
                  title: l.sellerFeature2Title,
                  subtitle: l.sellerFeature2Sub,
                ),
                const SizedBox(height: 14),
                _FeatureCard(
                  icon: Icons.forum_rounded,
                  title: l.sellerFeature3Title,
                  subtitle: l.sellerFeature3Sub,
                ),

                const Spacer(),

                // ── CTA ─────────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () => ref
                            .read(profileSetupProvider.notifier)
                            .saveOnboardingComplete(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.navyDark,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l.startExploring,
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.navyDark,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
