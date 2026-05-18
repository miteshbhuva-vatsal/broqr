import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';

class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.brokerUid,
    required super.brokerName,
    required super.category,
    required super.city,
    required super.location,
    required super.area,
    required super.price,
    required super.heroImageUrl,
    required super.status,
    required super.createdAt,
    super.title,
    super.areaUnit,
    super.brokerPhotoUrl,
    super.brokerPhone,
    super.propertyType,
    super.description,
    super.additionalImageUrls,
    super.posterUrl,
    super.brokerageAmount,
    super.posterRole,
    super.visibility,
    super.originalPrice,
    super.instagramUrl,
    super.pdfUrl,
    super.likesCount,
    super.commentsCount,
    super.viewsCount,
    super.contactsCount,
  });

  factory ListingModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,) {
    final d = doc.data() ?? {};
    return ListingModel(
      id: doc.id,
      brokerUid: d['brokerUid'] as String,
      brokerName: d['brokerName'] as String? ?? '',
      title: d['title'] as String?,
      brokerPhotoUrl: d['brokerPhotoUrl'] as String?,
      brokerPhone: d['brokerPhone'] as String?,
      propertyType: PropertyType.fromString(d['propertyType'] as String?),
      category: ListingCategory.fromString(d['category'] as String),
      city: d['city'] as String? ?? '',
      location: d['location'] as String? ?? '',
      area: (d['area'] as num?)?.toDouble() ?? 0,
      areaUnit: AreaUnit.fromString(d['areaUnit'] as String?),
      price: (d['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (d['originalPrice'] as num?)?.toDouble(),
      instagramUrl: d['instagramUrl'] as String?,
      pdfUrl: d['pdfUrl'] as String?,
      description: d['description'] as String?,
      heroImageUrl: d['heroImageUrl'] as String? ?? '',
      additionalImageUrls: List<String>.from(d['additionalImageUrls'] ?? []),
      posterUrl: d['posterUrl'] as String?,
      brokerageAmount: d['brokerageAmount'] as String?,
      posterRole: d['posterRole'] as String?,
      visibility: ListingVisibility.fromString(d['visibility'] as String?),
      status: _statusFrom(d['status'] as String?),
      likesCount: d['likesCount'] as int? ?? 0,
      commentsCount: d['commentsCount'] as int? ?? 0,
      viewsCount: d['viewsCount'] as int? ?? 0,
      contactsCount: d['contactsCount'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'brokerUid': brokerUid,
        'brokerName': brokerName,
        if (title != null && title!.isNotEmpty) 'title': title,
        'brokerPhotoUrl': brokerPhotoUrl,
        'brokerPhone': brokerPhone,
        'propertyType': propertyType?.firestoreKey,
        'category': category.name,
        'city': city,
        'location': location,
        'area': area,
        'areaUnit': areaUnit.name,
        'price': price,
        if (originalPrice != null) 'originalPrice': originalPrice,
        if (instagramUrl != null && instagramUrl!.isNotEmpty) 'instagramUrl': instagramUrl,
        if (pdfUrl != null && pdfUrl!.isNotEmpty) 'pdfUrl': pdfUrl,
        'description': description,
        'heroImageUrl': heroImageUrl,
        'additionalImageUrls': additionalImageUrls,
        'posterUrl': posterUrl,
        'brokerageAmount': brokerageAmount,
        'posterRole': posterRole,
        'visibility': visibility.name,
        'status': status.name,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'viewsCount': viewsCount,
        'contactsCount': contactsCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static ListingStatus _statusFrom(String? v) => switch (v) {
        'active' => ListingStatus.active,
        'inactive' => ListingStatus.inactive,
        'sold' => ListingStatus.sold,
        _ => ListingStatus.active,
      };
}
