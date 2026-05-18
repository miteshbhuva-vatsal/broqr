import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';

abstract interface class ListingRepository {
  Future<Either<Failure, Listing>> createListing({
    required String brokerUid,
    required String brokerName,
    required String? brokerPhotoUrl,
    required String? brokerPhone,
    required ListingCategory category,
    required String city,
    required String location,
    required double area,
    required double price,
    required String? description,
    required File heroImageFile,
    required List<File> additionalImageFiles,
    String? title,
    AreaUnit areaUnit = AreaUnit.sqFt,
    PropertyType? propertyType,
    String? brokerageAmount,
    String? posterRole,
    String? instagramUrl,
    File? pdfFile,
    ListingVisibility visibility = ListingVisibility.all,
    double? originalPrice,
    void Function(double)? onProgress,
  });

  Future<Either<Failure, String>> uploadPoster({
    required String listingId,
    required List<int> pngBytes,
  });

  Future<Either<Failure, List<Listing>>> fetchListings({
    ListingCategory? category,
    PropertyType? propertyType,
    DateTime? lastCreatedAt,
    String? lastListingId,
    int limit = 10,
    List<String>? brokerUids,
    String? currentUid,
    String? city,
  });

  Future<Either<Failure, List<Listing>>> fetchBrokerListings(
    String brokerUid, {
    DateTime? lastCreatedAt,
    String? lastDocId,
    int limit = 20,
  });

  Future<Either<Failure, Map<String, bool>>> fetchLikedStatusBatch(
    String uid,
    List<String> listingIds,
  );

  Future<Either<Failure, Map<String, bool>>> fetchInquiredStatusBatch(
    String uid,
    List<String> listingIds,
  );

  /// Partial in-place edit of a listing the user owns. Null params are skipped.
  Future<Either<Failure, Unit>> updateListing({
    required String listingId,
    String? title,
    double? price,
    String? brokerageAmount,
    String? description,
  });

  // ── Engagement ────────────────────────────────────────────────────────────

  Future<Either<Failure, List<String>>> fetchLikedListingIds(String uid);

  Future<Either<Failure, Unit>> likeListing({
    required String listingId,
    required String uid,
  });

  Future<Either<Failure, Unit>> unlikeListing({
    required String listingId,
    required String uid,
  });

  Future<Either<Failure, List<String>>> fetchInquiredListingIds(String uid);

  Future<Either<Failure, Unit>> recordInquiry({
    required String listingId,
    required String uid,
  });

  Future<Either<Failure, Unit>> incrementView({
    required String listingId,
    required String uid,
  });

  Future<Either<Failure, Unit>> deleteListing({required String listingId});

  Future<Either<Failure, Unit>> updateListingFull({
    required String listingId,
    required ListingCategory category,
    required String city,
    required String location,
    required double area,
    required AreaUnit areaUnit,
    required double price,
    required ListingVisibility visibility,
    String? title,
    PropertyType? propertyType,
    double? originalPrice,
    String? brokerageAmount,
    String? instagramUrl,
    String? description,
    File? newHeroImageFile,
    List<File> newAdditionalImageFiles,
    List<String> keptAdditionalImageUrls,
    File? newPdfFile,
    String? existingPdfUrl,
    void Function(double)? onProgress,
  });
}
