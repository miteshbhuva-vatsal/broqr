import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';

enum ListingCategory {
  barterDeal,
  bankAuction,
  bigDiscount,
  preLeased,
  preLaunched,
  preOwned,
  bestRoi,
  projectSpecific;

  // English label — used for Firestore storage, share text, notifications, PDF.
  String get label {
    return switch (this) {
      ListingCategory.barterDeal      => 'Barter Deal',
      ListingCategory.bankAuction     => 'Bank Auction',
      ListingCategory.bigDiscount     => 'Big Discount',
      ListingCategory.preLeased       => 'Pre-Leased',
      ListingCategory.preLaunched     => 'Pre-Launched',
      ListingCategory.preOwned        => 'Pre-Owned',
      ListingCategory.bestRoi         => 'Best ROI',
      ListingCategory.projectSpecific => 'Project Specific',
    };
  }

  // Locale-aware label for UI display.
  String localizedLabel(String langCode) {
    return switch (langCode) {
      'hi' => switch (this) {
        ListingCategory.barterDeal      => 'बार्टर डील',
        ListingCategory.bankAuction     => 'बैंक नीलामी',
        ListingCategory.bigDiscount     => 'बड़ी छूट',
        ListingCategory.preLeased       => 'प्री-लीज्ड',
        ListingCategory.preLaunched     => 'प्री-लॉन्च',
        ListingCategory.preOwned        => 'प्री-ओन्ड',
        ListingCategory.bestRoi         => 'बेस्ट ROI',
        ListingCategory.projectSpecific => 'प्रोजेक्ट स्पेसिफिक',
      },
      'gu' => switch (this) {
        ListingCategory.barterDeal      => 'બાર્ટર ડીલ',
        ListingCategory.bankAuction     => 'બેન્ક હરાજી',
        ListingCategory.bigDiscount     => 'મોટો ડિસ્કાઉન્ટ',
        ListingCategory.preLeased       => 'પ્રી-લીઝ્ડ',
        ListingCategory.preLaunched     => 'પ્રી-લૉન્ચ',
        ListingCategory.preOwned        => 'પ્રી-ઓન્ડ',
        ListingCategory.bestRoi         => 'બેસ્ટ ROI',
        ListingCategory.projectSpecific => 'પ્રોજેક્ટ સ્પેસિફિક',
      },
      _ => label, // English fallback
    };
  }

  String get emoji {
    return switch (this) {
      ListingCategory.barterDeal      => '🔄',
      ListingCategory.bankAuction     => '🏦',
      ListingCategory.bigDiscount     => '🏷️',
      ListingCategory.preLeased       => '🔑',
      ListingCategory.preLaunched     => '🚀',
      ListingCategory.preOwned        => '🏡',
      ListingCategory.bestRoi         => '📈',
      ListingCategory.projectSpecific => '🏗️',
    };
  }

  Color get color {
    return switch (this) {
      ListingCategory.barterDeal      => AppColors.catBarterDeal,
      ListingCategory.bankAuction     => AppColors.catBankAuction,
      ListingCategory.bigDiscount     => AppColors.catBigDiscount,
      ListingCategory.preLeased       => AppColors.catPreLeased,
      ListingCategory.preLaunched     => AppColors.catPreLaunched,
      ListingCategory.preOwned        => AppColors.catPreOwned,
      ListingCategory.bestRoi         => AppColors.catBestRoi,
      ListingCategory.projectSpecific => AppColors.catProjectSpecific,
    };
  }

  Color get bgColor => color.withValues(alpha: 0.12);

  static ListingCategory fromString(String value) {
    // Backwards-compat: map old Firestore keys to new values
    const legacy = {
      'barter':     ListingCategory.barterDeal,
      'project':    ListingCategory.projectSpecific,
      'investor':   ListingCategory.bestRoi,
      'discount':   ListingCategory.bigDiscount,
      'rental':     ListingCategory.preLeased,
      'commercial': ListingCategory.bankAuction,
      'urgentSale': ListingCategory.preOwned,
    };
    return legacy[value] ??
        ListingCategory.values.firstWhere(
          (e) => e.name == value,
          orElse: () => ListingCategory.barterDeal,
        );
  }
}
