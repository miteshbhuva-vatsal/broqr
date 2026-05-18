import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';
import 'package:cpapp/features/profile/presentation/widgets/city_picker_sheet.dart';
import 'package:cpapp/features/profile/presentation/widgets/profile_photo_picker.dart';
import 'package:cpapp/shared/widgets/app_button.dart';
import 'package:cpapp/shared/widgets/app_text_field.dart';
import 'package:cpapp/shared/widgets/loading_overlay.dart';
import 'package:cpapp/shared/widgets/locality_autocomplete.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _reraCtrl;

  String? _selectedCity;
  UserRole? _selectedRole;
  File? _photoFile;
  bool _submitted = false;
  bool _initialized = false;

  // Seller fields
  List<String> _dealCategories = [];
  List<String> _propertyTypes = [];
  List<String> _workingAreas = [];
  List<String> _memberships = [];
  bool _isProfilePublic = true;

  // Buyer fields
  String _userSubType = '';
  List<String> _preferredDealTypes = [];
  List<String> _preferredPropertyTypes = [];

  static const _membershipOptions = [
    'NAR India', 'CREDAI', 'NAREDCO', 'FIABCI', 'RERA Registered',
  ];

  static const _buyerSubTypes = [
    ('enduser',  '🏡', 'Home Buyer',  'Looking to buy / rent for personal use'),
    ('investor', '💰', 'Investor',    'Buying for investment or rental income'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _mobileCtrl = TextEditingController();
    _reraCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final user = ref.read(authStateChangesProvider).valueOrNull;
      if (user != null) {
        _nameCtrl.text = user.name;
        _mobileCtrl.text = user.mobile ?? '';
        _reraCtrl.text = user.reraNumber ?? '';
        _selectedCity = user.city;
        _selectedRole = user.role;
        _dealCategories = List<String>.from(user.dealCategories);
        _propertyTypes = List<String>.from(user.propertyTypes);
        _workingAreas = List<String>.from(user.workingAreas);
        _memberships = List<String>.from(user.memberships);
        _isProfilePublic = user.isProfilePublic;
        _userSubType = user.userSubType;
        _preferredDealTypes = List<String>.from(user.preferredDealTypes);
        _preferredPropertyTypes = List<String>.from(user.preferredPropertyTypes);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _reraCtrl.dispose();
    super.dispose();
  }

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
    if (_selectedCity == null || _selectedCity!.isEmpty) return 'Please select your city';
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

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate() || _validateCity() != null) return;

    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    if (user.isBuyer) {
      await ref.read(profileSetupProvider.notifier).updateProfile(
        uid: user.uid,
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        city: _selectedCity!,
        isProfilePublic: _isProfilePublic,
        userSubType: _userSubType.isEmpty ? null : _userSubType,
        preferredDealTypes: _preferredDealTypes,
        preferredPropertyTypes: _preferredPropertyTypes,
      );
    } else {
      await ref.read(profileSetupProvider.notifier).updateProfile(
        uid: user.uid,
        name: _nameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        city: _selectedCity!,
        role: _selectedRole,
        reraNumber: _reraCtrl.text.trim().isEmpty ? null : _reraCtrl.text.trim(),
        photoFile: _photoFile,
        dealCategories: _dealCategories,
        propertyTypes: _propertyTypes,
        workingAreas: _workingAreas,
        memberships: _memberships,
        isProfilePublic: _isProfilePublic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authStateChangesProvider).valueOrNull;

    ref.listen<ProfileSetupState>(profileSetupProvider, (_, next) {
      switch (next) {
        case ProfileSetupSuccess():
          ref.read(profileSetupProvider.notifier).clearError();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        case ProfileSetupError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
          );
          ref.read(profileSetupProvider.notifier).clearError();
        default:
          break;
      }
    });

    final setupState = ref.watch(profileSetupProvider);
    final isSaving = setupState is ProfileSetupSaving;
    final cityError = _submitted ? _validateCity() : null;
    final isBuyer = user?.isBuyer ?? false;

    return LoadingOverlay(
      isLoading: isSaving,
      message: 'Saving profile…',
      child: Scaffold(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
        appBar: AppBar(
          backgroundColor: AppColors.navyDark,
          foregroundColor: AppColors.white,
          title: Text('Edit Profile', style: AppTypography.titleSmall.copyWith(color: AppColors.white)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text('Tap to change photo',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  if (isBuyer) ...[
                    // ── BUYER FORM ─────────────────────────────────────────

                    // Buyer subtype
                    const _FieldLabel('I am a', required: false),
                    const SizedBox(height: 10),
                    ..._buyerSubTypes.map((entry) {
                      final (key, emoji, label, hint) = entry;
                      final selected = _userSubType == key;
                      return GestureDetector(
                        onTap: () => setState(() => _userSubType = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.gold.withValues(alpha: 0.12)
                                : (isDark ? AppColors.surfaceDark : AppColors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected ? AppColors.gold : (isDark ? AppColors.borderDark : AppColors.border),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 24)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label,
                                        style: AppTypography.labelMedium.copyWith(
                                          color: isDark ? AppColors.white : AppColors.navyDark,
                                          fontWeight: FontWeight.w700,
                                        ),),
                                    Text(hint,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.textSecondary, fontSize: 11,
                                        ),),
                                  ],
                                ),
                              ),
                              if (selected)
                                const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ] else ...[
                    // ── SELLER: Role selection ─────────────────────────────
                    const _FieldLabel('I am a', required: false),
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
                                onTap: () => setState(() => _selectedRole = role),
                              ),)
                          .toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Common: Full name ──────────────────────────────────────
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

                  // ── Common: Mobile ─────────────────────────────────────────
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

                  // ── Common: City ───────────────────────────────────────────
                  const _FieldLabel('City', required: true),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _pickCity,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cityError != null ? AppColors.error : (isDark ? AppColors.borderDark : AppColors.border),
                          width: cityError != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_city_outlined, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedCity ?? 'Select your city',
                              style: AppTypography.bodyMedium.copyWith(
                                color: _selectedCity != null
                                    ? (isDark ? AppColors.white : AppColors.textPrimary)
                                    : AppColors.textHint,
                              ),
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  if (cityError != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(cityError, style: AppTypography.labelSmall.copyWith(color: AppColors.error)),
                    ),
                  ],

                  if (isBuyer) ...[
                    // ── BUYER: Property preferences ────────────────────────
                    const SizedBox(height: 28),
                    _SectionDivider(label: 'Property Preferences', isDark: isDark),
                    const SizedBox(height: 20),

                    const _FieldLabel('Deal Types', required: false),
                    const SizedBox(height: 4),
                    Text('Select deal types you are interested in',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ListingCategory.values.map((cat) {
                        final selected = _preferredDealTypes.contains(cat.name);
                        return _MultiSelectChip(
                          label: '${cat.emoji} ${cat.label}',
                          selected: selected,
                          isDark: isDark,
                          onTap: () => setState(() {
                            if (selected) {
                              _preferredDealTypes.remove(cat.name);
                            } else {
                              _preferredDealTypes.add(cat.name);
                            }
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FieldLabel('Property Types', required: false),
                    const SizedBox(height: 4),
                    Text('Select property types you are looking for',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PropertyType.values.map((pt) {
                        final selected = _preferredPropertyTypes.contains(pt.firestoreKey);
                        return _MultiSelectChip(
                          label: '${pt.emoji} ${pt.label}',
                          selected: selected,
                          isDark: isDark,
                          onTap: () => setState(() {
                            if (selected) {
                              _preferredPropertyTypes.remove(pt.firestoreKey);
                            } else {
                              _preferredPropertyTypes.add(pt.firestoreKey);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    // ── SELLER: Expertise & specialisation ─────────────────
                    const SizedBox(height: 20),
                    const _FieldLabel('RERA Number', required: false),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _reraCtrl,
                      hint: 'e.g. MH/RERA/A12345 (optional)',
                      prefixIcon: const Icon(Icons.verified_user_outlined, size: 20),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.characters,
                    ),

                    const SizedBox(height: 28),
                    _SectionDivider(label: 'Expertise & Specialisation', isDark: isDark),
                    const SizedBox(height: 20),

                    const _FieldLabel('Deal Categories', required: false),
                    const SizedBox(height: 4),
                    Text('Select all deal types you work with',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ListingCategory.values.map((cat) {
                        final selected = _dealCategories.contains(cat.name);
                        return _MultiSelectChip(
                          label: '${cat.emoji} ${cat.label}',
                          selected: selected,
                          isDark: isDark,
                          onTap: () => setState(() {
                            if (selected) {
                              _dealCategories.remove(cat.name);
                            } else {
                              _dealCategories.add(cat.name);
                            }
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FieldLabel('Property Types', required: false),
                    const SizedBox(height: 4),
                    Text('Select property types you specialise in',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PropertyType.values.map((pt) {
                        final selected = _propertyTypes.contains(pt.firestoreKey);
                        return _MultiSelectChip(
                          label: '${pt.emoji} ${pt.label}',
                          selected: selected,
                          isDark: isDark,
                          onTap: () => setState(() {
                            if (selected) {
                              _propertyTypes.remove(pt.firestoreKey);
                            } else {
                              _propertyTypes.add(pt.firestoreKey);
                            }
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    const _FieldLabel('Preferred Working Areas', required: false),
                    const SizedBox(height: 4),
                    Text('Add localities or neighbourhoods you operate in',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),),
                    const SizedBox(height: 10),
                    LocalityMultiPicker(
                      selected: _workingAreas,
                      onChanged: (v) => setState(() => _workingAreas = v),
                      city: _selectedCity ?? '',
                    ),

                    const SizedBox(height: 24),

                    const _FieldLabel('Professional Memberships', required: false),
                    const SizedBox(height: 4),
                    Text('Select associations you are a member of',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _membershipOptions.map((m) {
                        final selected = _memberships.contains(m);
                        return _MultiSelectChip(
                          label: m,
                          selected: selected,
                          isDark: isDark,
                          onTap: () => setState(() {
                            if (selected) {
                              _memberships.remove(m);
                            } else {
                              _memberships.add(m);
                            }
                          }),
                        );
                      }).toList(),
                    ),

                  ],

                  // ── Common: Privacy ────────────────────────────────────────
                  const SizedBox(height: 28),
                  _SectionDivider(label: 'Privacy', isDark: isDark),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isProfilePublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                          size: 20,
                          color: _isProfilePublic ? AppColors.success : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isProfilePublic ? 'Public Profile' : 'Private Profile',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.white : AppColors.navyDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isProfilePublic
                                    ? 'Mobile number visible; Call & WhatsApp enabled'
                                    : 'Mobile number hidden; Call & WhatsApp disabled',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isProfilePublic,
                          activeThumbColor: AppColors.success,
                          onChanged: (v) => setState(() => _isProfilePublic = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Save button ────────────────────────────────────────────
                  AppButton(
                    label: 'Save Changes',
                    onPressed: isSaving ? null : _submit,
                    isLoading: isSaving,
                    suffixIcon: isSaving ? null : const Icon(Icons.check_rounded, size: 18, color: AppColors.navyDark),
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

// ── Multi-select chip ──────────────────────────────────────────────────────────

class _MultiSelectChip extends StatelessWidget {
  const _MultiSelectChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navyDark
              : (isDark ? AppColors.surfaceDark : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.navyDark
                : (isDark ? AppColors.borderDark : AppColors.border),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.white
                : (isDark ? AppColors.textOnDarkSecondary : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

// ── Section divider ────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.borderDark : AppColors.border;
    return Row(
      children: [
        Expanded(child: Divider(color: color, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(child: Divider(color: color, height: 1)),
      ],
    );
  }
}

// ── Role selection card ────────────────────────────────────────────────────────

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

// ── Field label ────────────────────────────────────────────────────────────────

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
