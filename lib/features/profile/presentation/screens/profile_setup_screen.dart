import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/providers/navigation_overrides.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';
import 'package:cpapp/features/profile/presentation/widgets/city_picker_sheet.dart';
import 'package:cpapp/features/profile/presentation/widgets/profile_photo_picker.dart' hide AppConstants;
import 'package:cpapp/shared/widgets/app_button.dart';
import 'package:cpapp/shared/widgets/app_text_field.dart';
import 'package:cpapp/shared/widgets/locality_autocomplete.dart';
import 'package:cpapp/shared/widgets/loading_overlay.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _reraCtrl;
  late final TextEditingController _companyCtrl;
  List<String> _workingAreas = [];
  String? _selectedCity;
  File? _photoFile;

  bool _submitted = false;
  bool _mobileVerified = false;

  String? _inviteOrgId;
  String? _inviteOrgName;

  static String _mobileFromAuthPhone() {
    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    if (phone.startsWith('+91') && phone.length == 13) return phone.substring(3);
    return '';
  }

  @override
  void initState() {
    super.initState();
    final user       = ref.read(authStateChangesProvider).valueOrNull;
    final authMobile = _mobileFromAuthPhone();
    final mobile     = user?.mobile?.isNotEmpty == true
        ? user!.mobile!
        : authMobile;
    _mobileVerified  = mobile.isNotEmpty &&
        (authMobile == mobile || (user?.isPhoneVerified ?? false));
    _nameCtrl    = TextEditingController(text: user?.name ?? '');
    _mobileCtrl  = TextEditingController(text: mobile);
    _reraCtrl    = TextEditingController();
    _companyCtrl = TextEditingController(text: user?.companyName ?? '');

    // Router populated pendingOrgInviteProvider during the auth flow — use it
    // directly so we avoid a redundant Firestore call and the invite banner
    // appears immediately without waiting for an async round-trip.
    final pendingInvite = ref.read(pendingOrgInviteProvider);
    if (pendingInvite != null) {
      _applyInviteData(pendingInvite);
    } else {
      final mobileToCheck = mobile.isNotEmpty ? mobile : authMobile;
      if (mobileToCheck.isNotEmpty) {
        _checkForPendingInvite(mobileToCheck);
      }
    }
  }

  void _applyInviteData(Map<String, dynamic> data) {
    final orgId   = data['orgId']   as String?;
    final orgName = data['orgName'] as String?;
    if (orgId == null) return;
    _inviteOrgId   = orgId;
    _inviteOrgName = orgName;
    if (orgName != null && _companyCtrl.text.isEmpty) {
      _companyCtrl.text = orgName;
    }
    // Defer provider mutation — initState runs during the build phase and
    // Riverpod forbids modifying providers until the tree is done building.
    Future.microtask(() {
      if (mounted) ref.read(currentOrgIdProvider.notifier).state = orgId;
    });
  }

  Future<void> _checkForPendingInvite(String mobile) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.orgInvitesCollection)
          .where('mobile', isEqualTo: mobile)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;
      final data = snap.docs.first.data();
      final orgId   = data['orgId']   as String?;
      final orgName = data['orgName'] as String?;
      if (orgId != null && mounted) {
        ref.read(currentOrgIdProvider.notifier).state = orgId;
        setState(() {
          _inviteOrgId   = orgId;
          _inviteOrgName = orgName;
          if (orgName != null && _companyCtrl.text.isEmpty) {
            _companyCtrl.text = orgName;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _reraCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final l = AppLocalizations.of(context);
    if (v == null || v.trim().length < 2) return l.enterFullName;
    return null;
  }

  String? _validateMobile(String? v) {
    final l = AppLocalizations.of(context);
    if (v == null || v.trim().isEmpty) return l.mobileRequired;
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) return l.invalidMobile;
    return null;
  }

  String? _validateCity() {
    final l = AppLocalizations.of(context);
    if (_selectedCity == null || _selectedCity!.isEmpty) return l.selectCity;
    return null;
  }

  Future<void> _pickCity() async {
    final city = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPickerSheet(selected: _selectedCity),
    );
    if (city != null) setState(() => _selectedCity = city);
  }

  Future<void> _submit({required bool isInvited}) async {
    setState(() => _submitted = true);
    final bool cityOk = _validateCity() == null;
    if (!_formKey.currentState!.validate() || !cityOk) return;

    final company  = _companyCtrl.text.trim();

    await ref.read(profileSetupProvider.notifier).saveProfile(
          name: _nameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          city: _selectedCity!,
          workingAreas: _workingAreas,
          role: null,
          reraNumber: _reraCtrl.text.trim().isEmpty ? null : _reraCtrl.text.trim(),
          photoFile: _photoFile,
          accountType: 'individual',
          companyName: company.isEmpty ? null : company,
          // Invited users join a broker team — mark them as sellers with
          // onboarding complete so they land straight in the CRM.
          userPersona: isInvited ? 'seller' : null,
          hasCompletedOnboarding: isInvited,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final user      = ref.watch(authStateChangesProvider).valueOrNull;
    final l         = AppLocalizations.of(context);
    final orgId     = ref.watch(currentOrgIdProvider);
    final isInvited = orgId != null || _inviteOrgId != null;
    final orgName   = _inviteOrgName
        ?? (isInvited ? ref.watch(watchCurrentOrgProvider).valueOrNull?.orgName : null);

    ref.listen<ProfileSetupState>(profileSetupProvider, (_, next) {
      switch (next) {
        case ProfileSetupSuccess():
          ref.read(profileCompleteOverrideProvider.notifier).state = true;
          if (isInvited) {
            final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
            if (uid.isNotEmpty) {
              ref.read(orgActionsProvider.notifier).acceptInviteByMobile(
                mobile: _mobileCtrl.text.trim(),
                brokerUid: uid,
                brokerName: _nameCtrl.text.trim(),
              );
            }
            // Team admin already configured the CRM — skip the onboarding
            // welcome screen and land the invited user directly in CRM.
            ref.read(onboardingCompleteOverrideProvider.notifier).state = true;
            context.go(Routes.crm);
          } else {
            // Router redirect handles onboarding routing:
            //   sellers  → /onboarding/seller
            //   buyers   → /onboarding/buyer
            context.go(Routes.feed);
          }
        case ProfileSetupError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          ref.read(profileSetupProvider.notifier).clearError();
        default:
          break;
      }
    });

    final setupState = ref.watch(profileSetupProvider);
    final isSaving   = setupState is ProfileSetupSaving;
    final cityError  = _submitted ? _validateCity() : null;
    final isSeller   = user?.isSeller ?? false;

    return LoadingOverlay(
      isLoading: isSaving,
      message: l.savingProfile,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Header ──────────────────────────────────────────────────
                  if (isInvited) ...[
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
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.domain_rounded,
                                  color: AppColors.gold,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  orgName ?? 'Your Organisation',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'You\'ve been invited to join ${orgName ?? 'the organisation'}.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Complete your profile to start collaborating with your team.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Sign Out'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.setupProfileTitle,
                                style: AppTypography.headlineMedium.copyWith(
                                  color: isDark ? AppColors.white : AppColors.navyDark,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l.setupProfileSubtitle,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout, size: 16),
                          label: const Text('Sign Out'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Profile photo ─────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        ProfilePhotoPicker(
                          currentFile: _photoFile,
                          networkUrl: user?.photoUrl,
                          onImagePicked: (f) => setState(() => _photoFile = f),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.tapToAddPhoto,
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Seller persona badge ──────────────────────────────────
                  if (isSeller) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10,),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              color: AppColors.gold, size: 18,),
                          const SizedBox(width: 8),
                          Text(
                            'Setting up your seller profile',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Full name ─────────────────────────────────────────────
                  _FieldLabel(l.fullName, required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    validator: _validateName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Rahul Sharma',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),

                  // ── Company name (sellers only) ───────────────────────────
                  if (isSeller) ...[
                    const SizedBox(height: 20),
                    const _FieldLabel('Company / Agency Name', required: false),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _companyCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Sharma Realty (optional)',
                        prefixIcon:
                            Icon(Icons.business_outlined, size: 20),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Mobile ────────────────────────────────────────────────
                  _FieldLabel(l.mobileNumber, required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _mobileCtrl,
                    validator: _validateMobile,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 10,
                    readOnly: _mobileVerified,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      prefixText: '+91  ',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      counterText: '',
                      suffixIcon: _mobileVerified
                          ? const Icon(Icons.verified, color: Colors.green, size: 20)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── City ──────────────────────────────────────────────────
                  _FieldLabel(l.city, required: true),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickCity,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14,),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cityError != null
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.border),
                          width: cityError != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city_outlined,
                              size: 20, color: AppColors.textSecondary,),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedCity ?? l.selectYourCity,
                              style: AppTypography.bodyMedium.copyWith(
                                color: _selectedCity != null
                                    ? (isDark
                                        ? AppColors.white
                                        : AppColors.textPrimary)
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,),
                        ],
                      ),
                    ),
                  ),
                  if (cityError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        cityError,
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],

                  // ── Preferred Working Areas ───────────────────────────────
                  const SizedBox(height: 20),
                  const _FieldLabel('Preferred Working Areas', required: false),
                  const SizedBox(height: 4),
                  Text(
                    'Add localities or neighbourhoods you operate in',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  LocalityMultiPicker(
                    selected: _workingAreas,
                    city: _selectedCity ?? '',
                    onChanged: (v) => setState(() => _workingAreas = v),
                  ),

                  // ── RERA (optional) ───────────────────────────────────────
                  const SizedBox(height: 20),
                  _FieldLabel(l.reraNumber, required: false),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _reraCtrl,
                    hint: 'e.g. MH/RERA/A12345 (optional)',
                    prefixIcon:
                        const Icon(Icons.verified_user_outlined, size: 20),
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.reraHint,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 40),

                  // ── Save button ───────────────────────────────────────────
                  AppButton(
                    label: isInvited ? 'Join Organisation' : l.saveAndContinue,
                    onPressed:
                        isSaving ? null : () => _submit(isInvited: isInvited),
                    isLoading: isSaving,
                    suffixIcon: isSaving
                        ? null
                        : const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: AppColors.navyDark,),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {required this.required});
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isDark
                ? AppColors.textOnDarkSecondary
                : AppColors.textSecondary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 3),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
