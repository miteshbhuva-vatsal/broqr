import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/providers/navigation_overrides.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

class SubscriptionPlanScreen extends ConsumerStatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  ConsumerState<SubscriptionPlanScreen> createState() =>
      _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState
    extends ConsumerState<SubscriptionPlanScreen> {
  int _step = 0; // 0: plan, 1: details, 2: payment
  String _plan = ''; // 'free' | 'individual' | 'team'

  final _companyCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _reraCtrl    = TextEditingController();
  final _areaCtrl    = TextEditingController();
  final Set<String> _associations  = {};
  final Set<String> _dealTypes     = {};
  final Set<String> _propertyTypes = {};
  bool _planError = false;
  bool _isSaving  = false;
  String _payMethod = 'upi';

  static const _assocOpts = [
    'CREDAI', 'NAREDCO', 'NAR India', 'GIHED', 'ARA', 'RERA Certified',
  ];
  static const _dealOpts = [
    'Residential Sale', 'Commercial Sale', 'Residential Rent',
    'Commercial Rent', 'Plot / Land', 'Lease',
  ];
  static const _propOpts = [
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

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  void _continueFromPlan() {
    if (_plan.isEmpty) {
      setState(() => _planError = true);
      return;
    }
    setState(() { _planError = false; _step = 1; });
  }

  void _continueFromDetails() {
    if (_plan == 'free') {
      _save();
    } else {
      setState(() => _step = 2);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
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
            planType:      _plan,
            companyName:   _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
            address:       _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
            reraNumber:    _reraCtrl.text.trim().isEmpty    ? null : _reraCtrl.text.trim(),
            preferredArea: _areaCtrl.text.trim().isEmpty    ? null : _areaCtrl.text.trim(),
            associations:  _associations.toList(),
            dealTypes:     _dealTypes.toList(),
            propertyTypes: _propertyTypes.toList(),
            orgId: orgId,
          );
      if (!mounted) return;
      // Immediately mark CRM setup done so the gateway doesn't re-appear
      // while authStateChangesProvider races to re-emit the updated flags.
      ref.read(crmSetupDoneProvider.notifier).state = true;
      // For team plan, sync the org ID into session immediately so the team
      // setup gate is also bypassed before the auth stream catches up.
      if (orgId != null) {
        ref.read(currentOrgIdProvider.notifier).state = orgId;
      }
      if (_plan == 'team') {
        context.go(Routes.organisation);
      } else {
        context.go(Routes.crm);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int get _totalSteps => (_plan == 'free' && _step >= 1) ? 2 : 3;

  String get _stepTitle {
    switch (_step) {
      case 0: return 'Choose Your Plan';
      case 1: return 'Your Details';
      case 2: return 'Payment';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: _back,
          color: isDark ? AppColors.white : AppColors.navyDark,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _stepTitle,
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Step ${_step + 1} of $_totalSteps',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_step + 1) / _totalSteps,
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            minHeight: 3,
          ),
        ),
      ),
      body: switch (_step) {
        0 => _buildPlanStep(isDark),
        1 => _buildDetailsStep(isDark),
        _ => _buildPaymentStep(isDark),
      },
    );
  }

  // ── Step 0: Plan selection ─────────────────────────────────────────────────

  Widget _buildPlanStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the plan that fits your business.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          _PlanCard(
            plan: 'free',
            title: 'Free Trial',
            badge: '1 MONTH FREE',
            badgeColor: AppColors.success,
            price: '₹0',
            period: 'for 1 month',
            description: 'Get started with no commitment.',
            features: const [
              'Up to 30 leads',
              'Basic CRM access',
              'Single user',
              'No credit card required',
            ],
            selected: _plan == 'free',
            isDark: isDark,
            onTap: () => setState(() { _plan = 'free'; _planError = false; }),
          ),
          const SizedBox(height: 14),

          _PlanCard(
            plan: 'individual',
            title: 'Individual',
            price: '₹999',
            period: '/month',
            description: 'For solo brokers growing their pipeline.',
            features: const [
              'Single user',
              'Up to 100 leads',
              'Full CRM access',
              'AI follow-up reminders',
            ],
            selected: _plan == 'individual',
            isDark: isDark,
            onTap: () => setState(() { _plan = 'individual'; _planError = false; }),
          ),
          const SizedBox(height: 14),

          _PlanCard(
            plan: 'team',
            title: 'Team',
            badge: 'POPULAR',
            price: '₹699',
            period: '/user/mo',
            description: 'For brokerages with multiple agents.',
            features: const [
              'Multi-user',
              'Unlimited leads',
              'AI insights & analytics',
              'Team collaboration',
            ],
            selected: _plan == 'team',
            isDark: isDark,
            onTap: () => setState(() { _plan = 'team'; _planError = false; }),
          ),

          if (_planError) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Please select a plan to continue',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),
          _CtaButton(
            label: 'Continue →',
            onPressed: _continueFromPlan,
            isLoading: false,
          ),
        ],
      ),
    );
  }

  // ── Step 1: Business details ───────────────────────────────────────────────

  Widget _buildDetailsStep(bool isDark) {
    final isFree = _plan == 'free';
    final isBuyer = ref.read(authStateChangesProvider).valueOrNull?.isBuyer ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your real estate business.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          _SectionLabel('Company / Agency Name', isDark: isDark),
          const SizedBox(height: 8),
          _FormField(
            controller: _companyCtrl,
            hint: 'e.g. Sharma Realty Pvt Ltd',
            icon: Icons.business_outlined,
          ),

          const SizedBox(height: 16),
          _SectionLabel('Office Address', isDark: isDark),
          const SizedBox(height: 8),
          _FormField(
            controller: _addressCtrl,
            hint: 'e.g. 3rd Floor, Times Square, Ahmedabad',
            icon: Icons.location_on_outlined,
          ),

          if (!isBuyer) ...[
            const SizedBox(height: 16),
            _SectionLabel('RERA Number (optional)', isDark: isDark),
            const SizedBox(height: 8),
            _FormField(
              controller: _reraCtrl,
              hint: 'e.g. MH/RERA/A12345',
              icon: Icons.verified_user_outlined,
              caps: TextCapitalization.characters,
            ),
          ],

          const SizedBox(height: 16),
          _SectionLabel('Preferred Working Area', isDark: isDark),
          const SizedBox(height: 8),
          _FormField(
            controller: _areaCtrl,
            hint: 'e.g. Vastrapur, Satellite',
            icon: Icons.map_outlined,
          ),

          const SizedBox(height: 22),
          _SectionLabel('Associations / Memberships', isDark: isDark),
          const SizedBox(height: 10),
          _ChipSelector(
            options: _assocOpts,
            selected: _associations,
            isDark: isDark,
            onToggle: (v) => setState(() {
              _associations.contains(v) ? _associations.remove(v) : _associations.add(v);
            }),
          ),

          const SizedBox(height: 22),
          _SectionLabel('Deal Types I Specialise In', isDark: isDark),
          const SizedBox(height: 10),
          _ChipSelector(
            options: _dealOpts,
            selected: _dealTypes,
            isDark: isDark,
            onToggle: (v) => setState(() {
              _dealTypes.contains(v) ? _dealTypes.remove(v) : _dealTypes.add(v);
            }),
          ),

          const SizedBox(height: 22),
          _SectionLabel('Property Types I Work With', isDark: isDark),
          const SizedBox(height: 10),
          _ChipSelector(
            options: _propOpts,
            selected: _propertyTypes,
            isDark: isDark,
            onToggle: (v) => setState(() {
              _propertyTypes.contains(v) ? _propertyTypes.remove(v) : _propertyTypes.add(v);
            }),
          ),

          const SizedBox(height: 32),
          _CtaButton(
            label: isFree ? 'Activate Free Plan →' : 'Continue to Payment →',
            onPressed: _continueFromDetails,
            isLoading: _isSaving && isFree,
          ),
        ],
      ),
    );
  }

  // ── Step 2: Payment ────────────────────────────────────────────────────────

  Widget _buildPaymentStep(bool isDark) {
    final planLabel = _plan == 'individual' ? 'Individual' : 'Team';
    final planPrice = _plan == 'individual' ? '₹999' : '₹699';
    final planPeriod = _plan == 'individual' ? '/month' : '/user/mo';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Plan summary ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navyDark, AppColors.navyMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: AppColors.gold, size: 24,),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$planLabel Plan',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Billed monthly · Cancel anytime',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      planPrice,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      planPeriod,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'PAYMENT METHOD',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),

          // ── Payment method pills ─────────────────────────────────────────
          Row(
            children: [
              _PayMethodPill(
                label: 'UPI',
                icon: Icons.account_balance_rounded,
                selected: _payMethod == 'upi',
                isDark: isDark,
                onTap: () => setState(() => _payMethod = 'upi'),
              ),
              const SizedBox(width: 10),
              _PayMethodPill(
                label: 'Card',
                icon: Icons.credit_card_rounded,
                selected: _payMethod == 'card',
                isDark: isDark,
                onTap: () => setState(() => _payMethod = 'card'),
              ),
              const SizedBox(width: 10),
              _PayMethodPill(
                label: 'Net Banking',
                icon: Icons.account_balance_outlined,
                selected: _payMethod == 'netbanking',
                isDark: isDark,
                onTap: () => setState(() => _payMethod = 'netbanking'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Payment detail input ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_payMethod == 'upi') ...[
                  Text(
                    'UPI ID',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'yourname@upi',
                      prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                      filled: true,
                      fillColor: isDark ? AppColors.navyDark : AppColors.offWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                ] else if (_payMethod == 'card') ...[
                  Text(
                    'Card Number',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: InputDecoration(
                      hintText: '•••• •••• •••• ••••',
                      prefixIcon: const Icon(Icons.credit_card_rounded, size: 18),
                      filled: true,
                      fillColor: isDark ? AppColors.navyDark : AppColors.offWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Select Bank',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    hint: const Text('Choose your bank'),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? AppColors.navyDark : AppColors.offWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'sbi', child: Text('State Bank of India')),
                      DropdownMenuItem(value: 'hdfc', child: Text('HDFC Bank')),
                      DropdownMenuItem(value: 'icici', child: Text('ICICI Bank')),
                      DropdownMenuItem(value: 'axis', child: Text('Axis Bank')),
                      DropdownMenuItem(value: 'kotak', child: Text('Kotak Mahindra Bank')),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Order summary ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$planLabel Plan',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      planPrice,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GST (18%)',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _plan == 'individual' ? '₹179.82' : '₹125.82',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _plan == 'individual' ? '₹1,178.82' : '₹824.82',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                'Secured by Razorpay · 256-bit SSL',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          _CtaButton(
            label: 'Activate Plan →',
            onPressed: _save,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  final String plan;
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.navyDark : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.navyDark
                      : (isDark ? AppColors.borderDark : AppColors.border),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: AppColors.white)
                  : null,
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge.copyWith(
                          color: selected
                              ? AppColors.navyDark
                              : (isDark ? AppColors.white : AppColors.textPrimary),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.navyDark
                                : (badgeColor ?? AppColors.gold),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: AppTypography.titleMedium.copyWith(
                          color: selected ? AppColors.navyDark : AppColors.gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2, left: 2),
                        child: Text(
                          period,
                          style: AppTypography.labelSmall.copyWith(
                            color: selected
                                ? AppColors.navyDark.withValues(alpha: 0.65)
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: selected
                          ? AppColors.navyDark.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
                            color: selected ? AppColors.navyDark : AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              f,
                              style: AppTypography.labelSmall.copyWith(
                                color: selected
                                    ? AppColors.navyDark
                                    : (isDark ? AppColors.white : AppColors.textPrimary),
                                fontSize: 12,
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
          ],
        ),
      ),
    );
  }
}

class _PayMethodPill extends StatelessWidget {
  const _PayMethodPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold
                : (isDark ? AppColors.surfaceDark : AppColors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.gold : (isDark ? AppColors.borderDark : AppColors.border),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.navyDark : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: selected ? AppColors.navyDark : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.isDark});
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

class _FormField extends StatelessWidget {
  const _FormField({
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
        fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
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

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
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
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyDark,
          disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDark),
              )
            : Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.navyDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
