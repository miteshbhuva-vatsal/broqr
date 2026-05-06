import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/l10n/locale_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/shared/widgets/app_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext(int slideCount) {
    if (_currentPage < slideCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final slides = [
      _OnboardingSlide(
        icon: Icons.home_work_outlined,
        title: l.slide1Title,
        subtitle: l.slide1Subtitle,
        color: AppColors.gold,
      ),
      _OnboardingSlide(
        icon: Icons.people_outline_rounded,
        title: l.slide2Title,
        subtitle: l.slide2Subtitle,
        color: AppColors.info,
      ),
      _OnboardingSlide(
        icon: Icons.assignment_turned_in_outlined,
        title: l.slide3Title,
        subtitle: l.slide3Subtitle,
        color: AppColors.success,
      ),
    ];

    final isLast = _currentPage == slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top row: skip + language
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => context.go(Routes.login),
                    child: Text(
                      l.skip,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _OnboardingLanguagePicker(l: l),
                ],
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideView(slide: slides[i]),
              ),
            ),

            // Indicator + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: slides.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.gold,
                      dotColor: AppColors.navyLight,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: isLast ? l.getStarted : l.next,
                    onPressed: () => _onNext(slides.length),
                    suffixIcon: Icon(
                      isLast
                          ? Icons.rocket_launch_outlined
                          : Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.navyDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language picker (compact icon button for onboarding) ──────────────────────

class _OnboardingLanguagePicker extends ConsumerWidget {
  const _OnboardingLanguagePicker({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    const labels = {'en': 'EN', 'hi': 'हिं', 'gu': 'ગુ'};
    final label = labels[current.languageCode] ?? 'EN';

    return GestureDetector(
      onTap: () => context.push(Routes.language),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                color: AppColors.gold, size: 14,),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slide view ────────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});
  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: slide.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, color: slide.color, size: 56),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textOnDarkSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
