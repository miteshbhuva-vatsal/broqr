import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';

/// Horizontal scrolling category filter row.
/// "All" chip + one chip per [ListingCategory].
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ListingCategory? selected;
  final ValueChanged<ListingCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'All',
            emoji: '🏠',
            isSelected: selected == null,
            selectedColor: AppColors.gold,
            onTap: () => onSelect(null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          ...ListingCategory.values.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: cat.localizedLabel(Localizations.localeOf(context).languageCode),
                emoji: cat.emoji,
                isSelected: selected == cat,
                selectedColor: cat.color,
                onTap: () => onSelect(cat),
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final String emoji;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : (isDark ? AppColors.borderDark : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected
                    ? (isSelected && selectedColor == AppColors.gold
                        ? AppColors.navyDark
                        : Colors.white)
                    : (isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary),
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
