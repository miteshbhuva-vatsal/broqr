import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

/// Step 1 — Buyer vs Seller selection.
/// Step 1A/2A — Sub-type selection within the chosen persona.
/// On completion: saves persona to Firestore; router then redirects to /profile-setup.
class PersonaSelectionScreen extends ConsumerStatefulWidget {
  const PersonaSelectionScreen({super.key});

  @override
  ConsumerState<PersonaSelectionScreen> createState() =>
      _PersonaSelectionScreenState();
}

class _PersonaSelectionScreenState
    extends ConsumerState<PersonaSelectionScreen> {
  int _step = 1; // 1 = persona, 2 = sub-type
  String _persona = ''; // 'buyer' | 'seller'
  String _subType = '';

  List<_SubOption> _buyerSubTypes(AppLocalizations l) => [
    _SubOption('enduser', '🏡', l.subHomeBuyer, l.subHomeBuyerHint),
    _SubOption('investor', '📈', l.subInvestorBuyer, l.subInvestorBuyerHint),
  ];

  List<_SubOption> _sellerSubTypes(AppLocalizations l) => [
    _SubOption('owner', '🏠', l.subPropertyOwner, l.subPropertyOwnerHint),
    _SubOption('broker', '🤝', l.subBrokerAgent, l.subBrokerAgentHint),
    _SubOption('builder', '🏗️', l.subBuilder, l.subBuilderHint),
    _SubOption('investor', '💼', l.subInvestorSeller, l.subInvestorSellerHint),
  ];

  List<_SubOption> _subOptions(AppLocalizations l) =>
      _persona == 'buyer' ? _buyerSubTypes(l) : _sellerSubTypes(l);

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    await ref.read(profileSetupProvider.notifier).savePersona(
          persona: _persona,
          subType: _subType,
          uid: uid,
        );
    // Router's redirect will detect hasPersona=true and navigate to /profile-setup.
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaving = ref.watch(profileSetupProvider) is ProfileSetupSaving;

    ref.listen<ProfileSetupState>(profileSetupProvider, (_, next) {
      if (next is ProfileSetupError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(profileSetupProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navyDark, AppColors.navyMid],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    if (_step == 2)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.white, size: 20,),
                        onPressed: () => setState(() {
                          _step = 1;
                          _subType = '';
                        }),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    // Step indicator dots
                    Row(
                      children: List.generate(2, (i) {
                        final active = i + 1 == _step;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.gold
                                : AppColors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Logo mark ──────────────────────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),

              const SizedBox(height: 20),

              // ── Heading ────────────────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 1
                    ? _Heading(
                        key: const ValueKey('h1'),
                        title: l.personaWelcomeTitle,
                        subtitle: l.personaWelcomeSubtitle,
                      )
                    : _Heading(
                        key: const ValueKey('h2'),
                        title: _persona == 'buyer'
                            ? l.personaWhatsYou
                            : l.personaYourRole,
                        subtitle: _persona == 'buyer'
                            ? l.personaPersonaliseSearch
                            : l.personaTailorWorkspace,
                      ),
              ),

              const SizedBox(height: 36),

              // ── Cards area ─────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _step == 1
                        ? _buildStep1(isDark, l)
                        : _buildStep2(isDark, l),
                  ),
                ),
              ),

              // ── Continue button ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _canProceed && !isSaving ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      disabledBackgroundColor:
                          AppColors.gold.withValues(alpha: 0.3),
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
                            _step == 1
                                ? '${l.personaContinue} →'
                                : '${l.personaSetupProfile} →',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.navyDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canProceed =>
      _step == 1 ? _persona.isNotEmpty : _subType.isNotEmpty;

  void _onContinue() {
    if (_step == 1) {
      setState(() => _step = 2);
    } else {
      _save();
    }
  }

  // ── Step 1: Buyer vs Seller ──────────────────────────────────────────────

  Widget _buildStep1(bool isDark, AppLocalizations l) {
    return Column(
      key: const ValueKey('step1'),
      children: [
        _PersonaCard(
          emoji: '🏠',
          title: l.personaBuyerTitle,
          subtitle: l.personaBuyerSubtitle,
          selected: _persona == 'buyer',
          onTap: () => setState(() => _persona = 'buyer'),
        ),
        const SizedBox(height: 16),
        _PersonaCard(
          emoji: '🏗️',
          title: l.personaSellerTitle,
          subtitle: l.personaSellerSubtitle,
          selected: _persona == 'seller',
          onTap: () => setState(() => _persona = 'seller'),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Step 2: Sub-type grid ────────────────────────────────────────────────

  Widget _buildStep2(bool isDark, AppLocalizations l) {
    final opts = _subOptions(l);
    final isBuyer = _persona == 'buyer';
    return Column(
      key: const ValueKey('step2'),
      children: [
        if (isBuyer)
          // 2 full-width cards stacked
          ...opts.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SubTypeCard(
                  option: o,
                  selected: _subType == o.key,
                  onTap: () => setState(() => _subType = o.key),
                ),
              ),)
        else
          // 2×2 grid for sellers — aspect ratio computed from actual card width
          LayoutBuilder(
            builder: (_, constraints) {
              final cardW = (constraints.maxWidth - 14) / 2;
              final ratio = (cardW / 96).clamp(1.05, 1.5);
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: ratio,
                children: opts
                    .map((o) => _SubTypeCard(
                          option: o,
                          selected: _subType == o.key,
                          onTap: () => setState(() => _subType = o.key),
                        ),)
                    .toList(),
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Heading ───────────────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  const _Heading({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.white.withValues(alpha: 0.65),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Persona card (Buyer / Seller) ─────────────────────────────────────────────

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.white.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      color: selected ? AppColors.navyDark : AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: selected
                          ? AppColors.navyDark.withValues(alpha: 0.7)
                          : AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: selected
                  ? AppColors.navyDark
                  : AppColors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-type card ─────────────────────────────────────────────────────────────

class _SubTypeCard extends StatelessWidget {
  const _SubTypeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SubOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : AppColors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.white.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              option.label,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? AppColors.navyDark : AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              option.sublabel,
              style: AppTypography.labelSmall.copyWith(
                color: selected
                    ? AppColors.navyDark.withValues(alpha: 0.65)
                    : AppColors.white.withValues(alpha: 0.55),
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data ──────────────────────────────────────────────────────────────────────

class _SubOption {
  const _SubOption(this.key, this.emoji, this.label, this.sublabel);
  final String key;
  final String emoji;
  final String label;
  final String sublabel;
}
