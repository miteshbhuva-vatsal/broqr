import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';

/// Base card widget with consistent styling.
/// Wraps [child] in a rounded, bordered surface.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 16,
    this.elevation = 0,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double elevation;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ??
        (isDark ? AppColors.surfaceDark : AppColors.white);
    final border = borderColor ??
        (isDark ? AppColors.borderDark : AppColors.border);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: 1),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.navyDark.withValues(alpha: 0.06),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(padding: padding, child: child),
              ),
            )
          : Padding(padding: padding, child: child),
    );
  }
}

/// A slim info row used inside cards (label + value).
class CardInfoRow extends StatelessWidget {
  const CardInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
