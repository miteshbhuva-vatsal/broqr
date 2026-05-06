import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';

/// Step 1 — Grid of 7 deal category cards.
class StepCategorySelector extends StatelessWidget {
  const StepCategorySelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ListingCategory? selected;
  final ValueChanged<ListingCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of deal\nare you posting?',
          style: AppTypography.headlineSmall.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the category that best describes your listing.',
          style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,),
        ),
        const SizedBox(height: 28),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemCount: ListingCategory.values.length,
          itemBuilder: (_, i) {
            final cat = ListingCategory.values[i];
            final isSelected = selected == cat;
            return _CategoryTile(
              category: cat,
              isSelected: isSelected,
              onTap: () => onSelect(cat),
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ListingCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.15)
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? category.color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category.emoji,
                    style: const TextStyle(fontSize: 22),),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: category.color, size: 18,),
              ],
            ),
            Text(
              category.localizedLabel(Localizations.localeOf(context).languageCode),
              style: AppTypography.titleSmall.copyWith(
                color: isSelected
                    ? category.color
                    : (isDark ? AppColors.white : AppColors.textPrimary),
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
