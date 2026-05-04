import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';

enum ListingCategory {
  barter,
  project,
  investor,
  discount,
  rental,
  commercial,
  urgentSale;

  String get label {
    return switch (this) {
      ListingCategory.barter => 'Barter Deal',
      ListingCategory.project => 'Project Deal',
      ListingCategory.investor => 'Investor Deal',
      ListingCategory.discount => 'Discount Deal',
      ListingCategory.rental => 'Rental Deal',
      ListingCategory.commercial => 'Commercial Deal',
      ListingCategory.urgentSale => 'Urgent Sale',
    };
  }

  String get emoji {
    return switch (this) {
      ListingCategory.barter => '🔄',
      ListingCategory.project => '🏗️',
      ListingCategory.investor => '📈',
      ListingCategory.discount => '🏷️',
      ListingCategory.rental => '🔑',
      ListingCategory.commercial => '🏢',
      ListingCategory.urgentSale => '⚡',
    };
  }

  Color get color {
    return switch (this) {
      ListingCategory.barter => AppColors.barter,
      ListingCategory.project => AppColors.project,
      ListingCategory.investor => AppColors.investor,
      ListingCategory.discount => AppColors.discount,
      ListingCategory.rental => AppColors.rental,
      ListingCategory.commercial => AppColors.commercial,
      ListingCategory.urgentSale => AppColors.urgentSale,
    };
  }

  Color get bgColor => color.withValues(alpha: 0.12);

  static ListingCategory fromString(String value) {
    return ListingCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ListingCategory.urgentSale,
    );
  }
}
