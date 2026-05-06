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

  Future<Either<Failure, List<Listing>>> fetchBrokerListings(String brokerUid);

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

  Future<Either<Failure, Unit>> incrementView({
    required String listingId,
    required String uid,
  });
}
