import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

/// Standardised text input used across all forms.
/// Supports prefix/suffix icons, phone input mode, and multiline.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.prefixText,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final String? prefixText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.labelMedium.copyWith(
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          textCapitalization: textCapitalization,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            errorText: errorText,
            helperText: helperText,
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Phone number field with Indian +91 prefix.
class PhoneTextField extends StatelessWidget {
  const PhoneTextField({
    super.key,
    this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: 'Mobile Number',
      hint: '9876543210',
      errorText: errorText,
      prefixText: '+91  ',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      maxLength: 10,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
    );
  }
}
