import 'package:flutter/material.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

/// Full-screen first-time walkthrough shown after initial profile setup.
/// 5 steps covering the main app features. Caller is responsible for
/// persisting the "seen" flag (SharedPreferences key: 'hasSeenAppGuide').
class AppGuide extends StatefulWidget {
  const AppGuide({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<AppGuide> createState() => _AppGuideState();
}

class _AppGuideState extends State<AppGuide>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  int _current = 0;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _next(int total) {
    if (_current < total - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _fadeCtrl.reverse().then((_) => widget.onDone());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final steps = [
      _GuideStep(
        icon: Icons.home_work_outlined,
        color: AppColors.gold,
        title: l.guide1Title,
        body: l.guide1Body,
      ),
      _GuideStep(
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.info,
        title: l.guide2Title,
        body: l.guide2Body,
      ),
      _GuideStep(
        icon: Icons.assignment_outlined,
        color: AppColors.success,
        title: l.guide3Title,
        body: l.guide3Body,
      ),
      _GuideStep(
        icon: Icons.people_outline_rounded,
        color: const Color(0xFF8B5CF6),
        title: l.guide4Title,
        body: l.guide4Body,
      ),
      _GuideStep(
        icon: Icons.alarm_outlined,
        color: AppColors.error,
        title: l.guide5Title,
        body: l.guide5Body,
      ),
    ];

    final isLast = _current == steps.length - 1;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: AppColors.navyDark,
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: step counter + skip
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      '${_current + 1} / ${steps.length}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textOnDarkSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onDone,
                      child: Text(
                        l.guideSkip,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: steps.length,
                  onPageChanged: (i) => setState(() => _current = i),
                  itemBuilder: (_, i) => _StepPage(step: steps[i]),
                ),
              ),

              // Dots + CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(steps.length, (i) {
                        final active = i == _current;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.gold
                                : AppColors.navyLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _next(steps.length),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.navyDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? l.guideDone : l.guideNext,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.navyDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isLast) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single step page ──────────────────────────────────────────────────────────

class _StepPage extends StatelessWidget {
  const _StepPage({required this.step});
  final _GuideStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.color, size: 58),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
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

class _GuideStep {
  const _GuideStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}
