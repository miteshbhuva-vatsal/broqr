import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/shared/widgets/app_button.dart';

/// 3-slide onboarding carousel explaining the app's value proposition.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardingSlide(
      icon: Icons.home_work_outlined,
      title: 'Find Stressed\nProperty Deals',
      subtitle:
          'Browse exclusive Barter, Investor & Discount deals shared directly by verified brokers.',
      color: AppColors.gold,
    ),
    _OnboardingSlide(
      icon: Icons.people_outline_rounded,
      title: 'Build Your\nBroker Network',
      subtitle:
          'Connect with brokers across your city. Share deals, collaborate, and grow your referral pipeline.',
      color: AppColors.info,
    ),
    _OnboardingSlide(
      icon: Icons.assignment_turned_in_outlined,
      title: 'Manage Leads\nLike a Pro',
      subtitle:
          'Built-in CRM to track every inquiry through your pipeline — from first contact to closed deal.',
      color: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
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
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go(Routes.login),
                child: Text(
                  'Skip',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),

            // Indicator + CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _slides.length,
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
                    label: isLast ? 'Get Started' : 'Next',
                    onPressed: _onNext,
                    suffixIcon: Icon(
                      isLast ? Icons.rocket_launch_outlined : Icons.arrow_forward_rounded,
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
          // Icon bubble
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
