import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

class AccountTypeSheet extends ConsumerStatefulWidget {
  const AccountTypeSheet({super.key});

  @override
  ConsumerState<AccountTypeSheet> createState() => _AccountTypeSheetState();
}

class _AccountTypeSheetState extends ConsumerState<AccountTypeSheet> {
  // ── step 1 = CRM intro, step 2 = plan + details ──────────────────────────
  int _step = 1;

  // ── Step 2 state ──────────────────────────────────────────────────────────
  String _plan = ''; // 'individual' | 'team'
  final _companyCtrl  = TextEditingController();
  final _addressCtrl  = TextEditingController();
  final _reraCtrl     = TextEditingController();
  final _areaCtrl     = TextEditingController();
  final Set<String> _associations   = {};
  final Set<String> _dealTypes      = {};
  final Set<String> _propertyTypes  = {};
  bool _submitted = false;

  static const _associationOptions = [
    'CREDAI', 'NAREDCO', 'NAR India', 'GIHED', 'ARA', 'RERA Certified',
  ];
  static const _dealTypeOptions = [
    'Residential Sale', 'Commercial Sale', 'Residential Rent',
    'Commercial Rent', 'Plot / Land', 'Lease',
  ];
  static const _propertyTypeOptions = [
    'Apartment', 'Villa / Bungalow', 'Plot', 'Office', 'Shop / Showroom',
    'Warehouse', 'Farmhouse', 'Studio',
  ];

  @override
  void dispose() {
    _companyCtrl.dispose();
    _addressCtrl.dispose();
    _reraCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    await ref.read(profileSetupProvider.notifier).saveAccountType(
          accountType: 'individual',
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_plan.isEmpty) return;

    String? orgId;
    if (_plan == 'team' && _companyCtrl.text.trim().isNotEmpty) {
      final user = ref.read(authStateChangesProvider).valueOrNull;
      if (user != null) {
        orgId = await ref.read(orgActionsProvider.notifier).createOrg(
              brokerUid: user.uid,
              brokerName: user.name,
              orgName: _companyCtrl.text.trim(),
            );
      }
    }

    await ref.read(profileSetupProvider.notifier).saveCrmSetup(
          planType: _plan,
          companyName: _companyCtrl.text.trim().isEmpty
              ? null
              : _companyCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          reraNumber: _reraCtrl.text.trim().isEmpty
              ? null
              : _reraCtrl.text.trim(),
          preferredArea: _areaCtrl.text.trim().isEmpty
              ? null
              : _areaCtrl.text.trim(),
          associations: _associations.toList(),
          dealTypes: _dealTypes.toList(),
          propertyTypes: _propertyTypes.toList(),
          orgId: orgId,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final isSaving = ref.watch(profileSetupProvider) is ProfileSetupSaving;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: _step == 1
            ? _buildIntro(isDark)
            : _buildSetup(isDark, isSaving),
      ),
    );
  }

  // ── Step 1: CRM intro ─────────────────────────────────────────────────────

  Widget _buildIntro(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DragHandle(isDark: isDark),
        const SizedBox(height: 20),

        // ── Header ──────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navyDark, AppColors.navyMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.gold,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your AI-Powered\nLead Manager',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Close more deals, faster — with smart CRM built for Indian real estate.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Feature bullets ──────────────────────────────────────────────────
        _FeatureBullet(
          icon: Icons.track_changes_rounded,
          text: 'Track every lead with smart status updates',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _FeatureBullet(
          icon: Icons.notifications_active_outlined,
          text: 'AI-assisted follow-up reminders so you never miss a deal',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _FeatureBullet(
          icon: Icons.bar_chart_rounded,
          text: 'Full pipeline view — from inquiry to closing',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _FeatureBullet(
          icon: Icons.groups_rounded,
          text: 'Team collaboration — share leads, assign tasks',
          isDark: isDark,
        ),

        const SizedBox(height: 32),

        // ── Yes CTA ───────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 2),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Yes, Set Up My CRM →',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Skip ─────────────────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _skip,
            child: Text(
              'Maybe Later',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Plan + details ────────────────────────────────────────────────

  Widget _buildSetup(bool isDark, bool isSaving) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DragHandle(isDark: isDark),
        const SizedBox(height: 16),

        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = 1),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'Choose Your Plan',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Plan cards ────────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _PlanCard(
                title: 'Individual',
                price: '₹999',
                period: '/month',
                features: const ['Single user', '100 leads', 'Full CRM access'],
                selected: _plan == 'individual',
                isDark: isDark,
                onTap: () => setState(() => _plan = 'individual'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PlanCard(
                title: 'Team',
                price: '₹699',
                period: '/user/mo',
                features: const [
                  'Multi-user',
                  'Unlimited leads',
                  'AI insights',
                ],
                selected: _plan == 'team',
                isDark: isDark,
                badge: 'POPULAR',
                onTap: () => setState(() => _plan = 'team'),
              ),
            ),
          ],
        ),

        if (_submitted && _plan.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Please select a plan',
            style: AppTypography.labelSmall.copyWith(color: AppColors.error),
          ),
        ],

        const SizedBox(height: 24),
        _Label('Company / Agency Name', isDark: isDark),
        const SizedBox(height: 8),
        _Field(
          controller: _companyCtrl,
          hint: 'e.g. Sharma Realty Pvt Ltd',
          icon: Icons.business_outlined,
        ),

        const SizedBox(height: 16),
        _Label('Office Address', isDark: isDark),
        const SizedBox(height: 8),
        _Field(
          controller: _addressCtrl,
          hint: 'e.g. 3rd Floor, Times Square, Ahmedabad',
          icon: Icons.location_on_outlined,
        ),

        const SizedBox(height: 16),
        _Label('RERA Number', isDark: isDark),
        const SizedBox(height: 8),
        _Field(
          controller: _reraCtrl,
          hint: 'e.g. MH/RERA/A12345 (optional)',
          icon: Icons.verified_user_outlined,
          caps: TextCapitalization.characters,
        ),

        const SizedBox(height: 16),
        _Label('Preferred Working Area', isDark: isDark),
        const SizedBox(height: 8),
        _Field(
          controller: _areaCtrl,
          hint: 'e.g. Vastrapur, Satellite',
          icon: Icons.map_outlined,
        ),

        const SizedBox(height: 20),
        _Label('Associations / Memberships', isDark: isDark),
        const SizedBox(height: 10),
        _ChipGroup(
          options: _associationOptions,
          selected: _associations,
          isDark: isDark,
          onToggle: (v) => setState(() {
            _associations.contains(v)
                ? _associations.remove(v)
                : _associations.add(v);
          }),
        ),

        const SizedBox(height: 20),
        _Label('Deal Types I Specialise In', isDark: isDark),
        const SizedBox(height: 10),
        _ChipGroup(
          options: _dealTypeOptions,
          selected: _dealTypes,
          isDark: isDark,
          onToggle: (v) => setState(() {
            _dealTypes.contains(v)
                ? _dealTypes.remove(v)
                : _dealTypes.add(v);
          }),
        ),

        const SizedBox(height: 20),
        _Label('Property Types I Work With', isDark: isDark),
        const SizedBox(height: 10),
        _ChipGroup(
          options: _propertyTypeOptions,
          selected: _propertyTypes,
          isDark: isDark,
          onToggle: (v) => setState(() {
            _propertyTypes.contains(v)
                ? _propertyTypes.remove(v)
                : _propertyTypes.add(v);
          }),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.navyDark,
                    ),
                  )
                : Text(
                    'Save & Add First Property →',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.navyDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({
    required this.icon,
    required this.text,
    required this.isDark,
  });
  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? AppColors.white : AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.isDark});
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.caps = TextCapitalization.words,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextCapitalization caps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      textCapitalization: caps,
      textInputAction: TextInputAction.next,
      inputFormatters: [LengthLimitingTextInputFormatter(120)],
      style: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.options,
    required this.selected,
    required this.isDark,
    required this.onToggle,
  });
  final List<String> options;
  final Set<String> selected;
  final bool isDark;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected.contains(o);
        return GestureDetector(
          onTap: () => onToggle(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.gold
                  : (isDark ? AppColors.surfaceDark : AppColors.offWhite),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.gold
                    : (isDark ? AppColors.borderDark : AppColors.border),
              ),
            ),
            child: Text(
              o,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.navyDark
                    : (isDark ? AppColors.white : AppColors.textPrimary),
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.badge,
  });
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : (isDark ? AppColors.surfaceDark : AppColors.offWhite),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.navyDark
                      : AppColors.gold,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            if (badge != null) const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: selected
                    ? AppColors.navyDark
                    : (isDark ? AppColors.white : AppColors.textPrimary),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: AppTypography.titleMedium.copyWith(
                    color: selected
                        ? AppColors.navyDark
                        : AppColors.gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    period,
                    style: AppTypography.labelSmall.copyWith(
                      color: selected
                          ? AppColors.navyDark.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: selected
                          ? AppColors.navyDark
                          : AppColors.success,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTypography.labelSmall.copyWith(
                          color: selected
                              ? AppColors.navyDark
                              : (isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
