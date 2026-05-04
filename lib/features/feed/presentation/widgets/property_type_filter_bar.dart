import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';

class PropertyTypeFilterBar extends StatelessWidget {
  const PropertyTypeFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final PropertyType? selected;
  final ValueChanged<PropertyType?> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _PTChip(
            label: 'All Types',
            emoji: '🏠',
            isSelected: selected == null,
            onTap: () => onSelect(null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          ...PropertyType.values.map((pt) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PTChip(
                label: pt.label,
                emoji: pt.emoji,
                isSelected: selected == pt,
                onTap: () => onSelect(pt),
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PTChip extends StatelessWidget {
  const _PTChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.navyDark
                    : (isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
