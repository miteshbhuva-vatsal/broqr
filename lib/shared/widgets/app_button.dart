import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';

/// Variant selector for [AppButton].
enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// Reusable button with loading state, icon support, and full-width option.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.suffixIcon,
    this.height = 52,
    this.borderRadius = 12,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: _buildButton(context, isDark),
    );
  }

  Widget _buildButton(BuildContext context, bool isDark) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
            disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(color: AppColors.navyDark),
        );

      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyDark,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(color: AppColors.white),
        );

      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.navyDark,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(
            color: isDark ? AppColors.white : AppColors.navyDark,
          ),
        );

      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(color: AppColors.gold),
        );

      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: _buildChild(color: AppColors.white),
        );
    }
  }

  Widget _buildChild({required Color color}) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (prefixIcon == null && suffixIcon == null) {
      return Text(
        label,
        style: AppTypography.labelLarge.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (prefixIcon != null) ...[
          prefixIcon!,
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (suffixIcon != null) ...[
          const SizedBox(width: 8),
          suffixIcon!,
        ],
      ],
    );
  }
}

/// A slim social-style auth button (Google, Facebook, Apple).
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
          side: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
