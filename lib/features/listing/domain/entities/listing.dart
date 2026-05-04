import 'package:equatable/equatable.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';

enum AreaUnit {
  sqFt,
  sqM,
  sqYd;

  static AreaUnit fromString(String? v) => switch (v) {
        'sqM' => sqM,
        'sqYd' => sqYd,
        _ => sqFt,
      };

  String get label => switch (this) {
        AreaUnit.sqFt => 'Sq.ft',
        AreaUnit.sqM => 'Sq.m',
        AreaUnit.sqYd => 'Sq.yd',
      };
}

enum ListingStatus { active, inactive, sold }

enum ListingVisibility {
  onlyMe,
  network,
  all;

  static ListingVisibility fromString(String? v) => switch (v) {
        'onlyMe' => onlyMe,
        'network' => network,
        _ => all,
      };

  String get label => switch (this) {
        ListingVisibility.onlyMe => 'Only Me',
        ListingVisibility.network => 'My Network',
        ListingVisibility.all => 'All Users',
      };

  String get emoji => switch (this) {
        ListingVisibility.onlyMe => '🔒',
        ListingVisibility.network => '🤝',
        ListingVisibility.all => '🌐',
      };

  String get description => switch (this) {
        ListingVisibility.onlyMe => 'Only visible to you',
        ListingVisibility.network => 'Visible to your connections',
        ListingVisibility.all => 'Visible to all brokers',
      };
}

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.brokerUid,
    required this.brokerName,
    required this.category,
    required this.city,
    required this.location,
    required this.area,
    required this.price,
    required this.heroImageUrl,
    required this.status,
    required this.createdAt,
    this.title,
    this.areaUnit = AreaUnit.sqFt,
    this.brokerPhotoUrl,
    this.brokerPhone,
    this.propertyType,
    this.description,
    this.additionalImageUrls = const [],
    this.posterUrl,
    this.brokerageAmount,
    this.posterRole,
    this.visibility = ListingVisibility.all,
    this.originalPrice,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
  });

  final String id;
  final String brokerUid;
  final String brokerName;
  final String? title;
  final String? brokerPhotoUrl;
  final String? brokerPhone;
  final PropertyType? propertyType;
  final ListingCategory category;
  final String city;
  final String location;
  final double area;
  final AreaUnit areaUnit;
  final double price;
  /// Optional market/MRP price. When set and > [price], the UI shows a
  /// strikethrough on this value and a discount badge.
  final double? originalPrice;
  final String? description;
  final String heroImageUrl;
  final List<String> additionalImageUrls;
  final String? posterUrl;
  final String? brokerageAmount;
  final String? posterRole;
  final ListingVisibility visibility;
  final ListingStatus status;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;

  String get priceLabel {
    if (price >= 10000000) return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    if (price >= 100000) return '₹${(price / 100000).toStringAsFixed(2)} L';
    return '₹${price.toStringAsFixed(0)}';
  }

  String get areaLabel => '${area.toStringAsFixed(0)} ${areaUnit.label}';

  String? get originalPriceLabel {
    if (originalPrice == null) return null;
    final op = originalPrice!;
    if (op >= 10000000) return '₹${(op / 10000000).toStringAsFixed(2)} Cr';
    if (op >= 100000) return '₹${(op / 100000).toStringAsFixed(2)} L';
    return '₹${op.toStringAsFixed(0)}';
  }

  /// Percentage saved vs [originalPrice]. Null when no discount is set.
  int? get discountPercent {
    if (originalPrice == null || originalPrice! <= price || originalPrice! == 0) {
      return null;
    }
    return ((originalPrice! - price) / originalPrice! * 100).round();
  }

  Listing copyWith({
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    String? posterUrl,
    String? brokerageAmount,
    String? posterRole,
    ListingVisibility? visibility,
    ListingStatus? status,
  }) {
    return Listing(
      id: id,
      brokerUid: brokerUid,
      brokerName: brokerName,
      title: title,
      brokerPhotoUrl: brokerPhotoUrl,
      brokerPhone: brokerPhone,
      propertyType: propertyType,
      category: category,
      city: city,
      location: location,
      area: area,
      areaUnit: areaUnit,
      price: price,
      originalPrice: originalPrice,
      description: description,
      heroImageUrl: heroImageUrl,
      additionalImageUrls: additionalImageUrls,
      posterUrl: posterUrl ?? this.posterUrl,
      brokerageAmount: brokerageAmount ?? this.brokerageAmount,
      posterRole: posterRole ?? this.posterRole,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brokerUid,
        category,
        city,
        location,
        price,
        originalPrice,
        brokerageAmount,
        posterRole,
        visibility,
        status,
        createdAt,
      ];
}
