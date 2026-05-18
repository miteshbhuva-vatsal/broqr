import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/listing/data/datasources/listing_remote_datasource.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/listing/domain/repositories/listing_repository.dart';

class ListingRepositoryImpl implements ListingRepository {
  const ListingRepositoryImpl({required ListingRemoteDataSource dataSource})
      : _ds = dataSource;

  final ListingRemoteDataSource _ds;

  @override
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
  }) async {
    try {
      final model = await _ds.createListing(
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
        heroImageFile: heroImageFile,
        additionalImageFiles: additionalImageFiles,
        brokerageAmount: brokerageAmount,
        posterRole: posterRole,
        instagramUrl: instagramUrl,
        pdfFile: pdfFile,
        visibility: visibility,
        onProgress: onProgress,
      );
      return Right(model);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPoster({
    required String listingId,
    required List<int> pngBytes,
  }) async {
    try {
      final url = await _ds.uploadPoster(
        listingId: listingId,
        pngBytes: pngBytes,
      );
      return Right(url);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Listing>>> fetchListings({
    ListingCategory? category,
    PropertyType? propertyType,
    DateTime? lastCreatedAt,
    String? lastListingId,
    int limit = 10,
    List<String>? brokerUids,
    String? currentUid,
    String? city,
  }) async {
    try {
      final list = await _ds.fetchListings(
        category: category,
        propertyType: propertyType,
        lastCreatedAt: lastCreatedAt,
        lastListingId: lastListingId,
        limit: limit,
        brokerUids: brokerUids,
        currentUid: currentUid,
        city: city,
      );
      return Right(list);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Listing>>> fetchBrokerListings(
    String brokerUid, {
    DateTime? lastCreatedAt,
    String? lastDocId,
    int limit = 20,
  }) async {
    try {
      final list = await _ds.fetchBrokerListings(
        brokerUid,
        lastCreatedAt: lastCreatedAt,
        lastDocId: lastDocId,
        limit: limit,
      );
      return Right(list);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> fetchLikedStatusBatch(
    String uid,
    List<String> listingIds,
  ) async {
    try {
      final map = await _ds.fetchLikedStatusBatch(uid, listingIds);
      return Right(map);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, bool>>> fetchInquiredStatusBatch(
    String uid,
    List<String> listingIds,
  ) async {
    try {
      final map = await _ds.fetchInquiredStatusBatch(uid, listingIds);
      return Right(map);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateListing({
    required String listingId,
    String? title,
    double? price,
    String? brokerageAmount,
    String? description,
  }) async {
    try {
      await _ds.updateListing(
        listingId: listingId,
        title: title,
        price: price,
        brokerageAmount: brokerageAmount,
        description: description,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> fetchLikedListingIds(
    String uid,
  ) async {
    try {
      final ids = await _ds.fetchLikedListingIds(uid);
      return Right(ids);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> likeListing({
    required String listingId,
    required String uid,
  }) async {
    try {
      await _ds.likeListing(listingId: listingId, uid: uid);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unlikeListing({
    required String listingId,
    required String uid,
  }) async {
    try {
      await _ds.unlikeListing(listingId: listingId, uid: uid);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> fetchInquiredListingIds(
    String uid,
  ) async {
    try {
      final ids = await _ds.fetchInquiredListingIds(uid);
      return Right(ids);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> recordInquiry({
    required String listingId,
    required String uid,
  }) async {
    try {
      await _ds.recordInquiry(listingId: listingId, uid: uid);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> incrementView({
    required String listingId,
    required String uid,
  }) async {
    try {
      await _ds.incrementView(listingId: listingId, uid: uid);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteListing({
    required String listingId,
  }) async {
    try {
      await _ds.deleteListing(listingId: listingId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
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
    List<File> newAdditionalImageFiles = const [],
    List<String> keptAdditionalImageUrls = const [],
    File? newPdfFile,
    String? existingPdfUrl,
    void Function(double)? onProgress,
  }) async {
    try {
      await _ds.updateListingFull(
        listingId: listingId,
        category: category,
        city: city,
        location: location,
        area: area,
        areaUnit: areaUnit,
        price: price,
        visibility: visibility,
        title: title,
        propertyType: propertyType,
        originalPrice: originalPrice,
        brokerageAmount: brokerageAmount,
        instagramUrl: instagramUrl,
        description: description,
        newHeroImageFile: newHeroImageFile,
        newAdditionalImageFiles: newAdditionalImageFiles,
        keptAdditionalImageUrls: keptAdditionalImageUrls,
        newPdfFile: newPdfFile,
        existingPdfUrl: existingPdfUrl,
        onProgress: onProgress,
      );
      return const Right(unit);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
