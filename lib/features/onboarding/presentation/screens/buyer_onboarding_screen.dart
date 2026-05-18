import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

/// Step 1C — Buyer property preference filter.
/// Shown once after profile setup for buyers; sets hasCompletedOnboarding=true.
class BuyerOnboardingScreen extends ConsumerStatefulWidget {
  const BuyerOnboardingScreen({super.key});

  @override
  ConsumerState<BuyerOnboardingScreen> createState() =>
      _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState
    extends ConsumerState<BuyerOnboardingScreen> {
  final Set<String> _propertyTypes = {};
  final Set<String> _dealTypes = {};

  List<_Chip> _propertyOptions(AppLocalizations l) => [
    _Chip('apartment', '🏢', l.chipApartment),
    _Chip('villa', '🏡', l.chipVilla),
    _Chip('plot', '🌳', l.chipPlot),
    _Chip('office', '🏢', l.chipOffice),
    _Chip('shop', '🏪', l.chipShop),
    _Chip('warehouse', '🏭', l.chipWarehouse),
    _Chip('farmhouse', '🌾', l.chipFarmhouse),
    _Chip('studio', '🛋️', l.chipStudio),
  ];

  List<_Chip> _dealOptions(AppLocalizations l) => [
    _Chip('buy', '💰', l.chipBuy),
    _Chip('rent', '🔑', l.chipRent),
    _Chip('lease', '📋', l.chipLease),
  ];

  bool get _canProceed =>
      _propertyTypes.isNotEmpty && _dealTypes.isNotEmpty;

  Future<void> _save() async {
    await ref.read(profileSetupProvider.notifier).saveBuyerPreferences(
          propertyTypes: _propertyTypes.toList(),
          dealTypes: _dealTypes.toList(),
        );
  }

  Future<void> _skip() async {
    // Mark onboarding done without saving preferences.
    await ref.read(profileSetupProvider.notifier).saveBuyerPreferences(
          propertyTypes: const [],
          dealTypes: const [],
        );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaving = ref.watch(profileSetupProvider) is ProfileSetupSaving;

    ref.listen<ProfileSetupState>(profileSetupProvider, (_, next) {
      if (next is ProfileSetupSuccess && mounted) {
        context.go(Routes.feed);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: isDark
                          ? AppColors.borderDark
                          : AppColors.border,
                      color: AppColors.gold,
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.buyerStep,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l.buyerOnboardingTitle,
                    style: AppTypography.headlineMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.navyDark,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.buyerOnboardingSubtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable content ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property type
                    _SectionLabel(
                      l.buyerPropType,
                      hint: l.selectAllApply,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _propertyOptions(l).map((c) {
                        final sel = _propertyTypes.contains(c.key);
                        return _FilterChip(
                          chip: c,
                          selected: sel,
                          isDark: isDark,
                          onTap: () => setState(() {
                            if (sel) {
                              _propertyTypes.remove(c.key);
                            } else {
                              _propertyTypes.add(c.key);
                            }
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),

                    // Deal type
                    _SectionLabel(
                      l.buyerLookingTo,
                      hint: l.selectAllApply,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _dealOptions(l).map((c) {
                        final sel = _dealTypes.contains(c.key);
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _FilterChip(
                            chip: c,
                            selected: sel,
                            isDark: isDark,
                            large: true,
                            onTap: () => setState(() {
                              if (sel) {
                                _dealTypes.remove(c.key);
                              } else {
                                _dealTypes.add(c.key);
                              }
                            }),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Footer buttons ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              decoration: BoxDecoration(
                color: isDark ? AppColors.navyDark : AppColors.offWhite,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canProceed && !isSaving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                        disabledBackgroundColor:
                            AppColors.gold.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          : Text(
                              '${l.showMeProperties} →',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.navyDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: isSaving ? null : _skip,
                    child: Text(
                      l.skipForNow,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textSecondary,
                      ),
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

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.hint, required this.isDark});
  final String text;
  final String hint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          hint,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textHint,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.chip,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.large = false,
  });

  final _Chip chip;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : 14,
          vertical: large ? 12 : 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chip.emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              chip.label,
              style: AppTypography.labelMedium.copyWith(
                color: selected
                    ? AppColors.navyDark
                    : (isDark ? AppColors.white : AppColors.textPrimary),
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _Chip {
  const _Chip(this.key, this.emoji, this.label);
  final String key;
  final String emoji;
  final String label;
}
