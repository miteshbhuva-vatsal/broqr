import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/router/app_router.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';
import 'package:cpapp/features/profile/presentation/widgets/city_picker_sheet.dart';
import 'package:cpapp/features/profile/presentation/widgets/profile_photo_picker.dart';
import 'package:cpapp/shared/widgets/app_button.dart';
import 'package:cpapp/shared/widgets/app_text_field.dart';
import 'package:cpapp/shared/widgets/loading_overlay.dart';

/// Broker profile setup — shown once after first social login.
/// Collects: display name, mobile, city, RERA (optional), profile photo.
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

  String? _selectedCity;
  UserRole? _selectedRole;
  File? _photoFile;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from social login profile
    final user = ref.read(authStateChangesProvider).valueOrNull;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _mobileCtrl = TextEditingController(text: user?.mobile ?? '');
    _reraCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _reraCtrl.dispose();
    super.dispose();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  String? _validateName(String? v) {
    if (v == null || v.trim().length < 2) return 'Enter your full name';
    return null;
  }

  String? _validateMobile(String? v) {
    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  String? _validateCity() {
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      return 'Please select your city';
    }
    return null;
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickCity() async {
    final city = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CityPickerSheet(selected: _selectedCity),
    );
    if (city != null) setState(() => _selectedCity = city);
  }

  String? _validateRole() =>
      _selectedRole == null ? 'Please select your role' : null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() ||
        _validateCity() != null ||
        _validateRole() != null) {
      return;
    }

    await ref.read(profileSetupProvider.notifier).saveProfile(
          name: _nameCtrl.text.trim(),
          mobile: _mobileCtrl.text.trim(),
          city: _selectedCity!,
          role: _selectedRole!,
          reraNumber: _reraCtrl.text.trim().isEmpty ? null : _reraCtrl.text.trim(),
          photoFile: _photoFile,
        );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    // Listen for save result → navigate or show error
    ref.listen<ProfileSetupState>(profileSetupProvider, (_, next) {
      switch (next) {
        case ProfileSetupSuccess():
          ref.read(profileCompleteOverrideProvider.notifier).state = true;
          context.go(Routes.feed);
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
    final isSaving = setupState is ProfileSetupSaving;
    final cityError = _submitted ? _validateCity() : null;

    return LoadingOverlay(
      isLoading: isSaving,
      message: 'Saving your profile…',
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.navyDark : AppColors.offWhite,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // ── Header ──────────────────────────────────────────────
                  Text(
                    'Set Up Your Profile',
                    style: AppTypography.headlineMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.navyDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tell us who you are so others can connect with you.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Role selection ───────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'I am a',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
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
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: UserRole.values
                        .map((role) => _RoleCard(
                              role: role,
                              isSelected: _selectedRole == role,
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _selectedRole = role),
                            ),)
                        .toList(),
                  ),
                  if (_submitted && _validateRole() != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _validateRole()!,
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Profile photo ────────────────────────────────────────
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
                          'Tap to add profile photo',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Full name ────────────────────────────────────────────
                  const _FieldLabel('Full Name', required: true),
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

                  const SizedBox(height: 20),

                  // ── Mobile ───────────────────────────────────────────────
                  const _FieldLabel('Mobile Number', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _mobileCtrl,
                    validator: _validateMobile,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '9876543210',
                      prefixText: '+91  ',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── City ─────────────────────────────────────────────────
                  const _FieldLabel('City', required: true),
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
                          const Icon(
                            Icons.location_city_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedCity ?? 'Select your city',
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
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── RERA (optional) ──────────────────────────────────────
                  const _FieldLabel('RERA Number', required: false),
                  const SizedBox(height: 6),
                  AppTextField(
                    controller: _reraCtrl,
                    hint: 'e.g. MH/RERA/A12345 (optional)',
                    prefixIcon: const Icon(
                        Icons.verified_user_outlined, size: 20,),
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leave blank if not yet registered with RERA',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Save button ──────────────────────────────────────────
                  AppButton(
                    label: 'Save & Continue',
                    onPressed: isSaving ? null : _submit,
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

// ── Role selection card ────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(role.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              role.label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? AppColors.navyDark
                    : (isDark ? AppColors.white : AppColors.textPrimary),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              role.description,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.navyDark.withValues(alpha: 0.7)
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable field label ────────────────────────────────────────────────────

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
          const Text('*',
              style: TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,),),
        ],
      ],
    );
  }
}
