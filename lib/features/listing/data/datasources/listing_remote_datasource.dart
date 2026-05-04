import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/listing/data/models/listing_model.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';

abstract interface class ListingRemoteDataSource {
  Future<ListingModel> createListing({
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
  });

  Future<String> uploadPoster({
    required String listingId,
    required List<int> pngBytes,
  });

  Future<List<ListingModel>> fetchListings({
    ListingCategory? category,
    PropertyType? propertyType,
    DateTime? lastCreatedAt,
    String? lastListingId,
    int limit = 10,
    List<String>? brokerUids,
    String? currentUid,
    String? city,
  });

  Future<List<ListingModel>> fetchBrokerListings(String brokerUid);

  Future<List<String>> fetchLikedListingIds(String uid);

  Future<void> likeListing({required String listingId, required String uid});

  Future<void> unlikeListing({required String listingId, required String uid});

  Future<void> incrementView({required String listingId, required String uid});
}

class ListingRemoteDataSourceImpl implements ListingRemoteDataSource {
  const ListingRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _db = firestore,
        _storage = storage;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  @override
  Future<ListingModel> createListing({
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
  }) async {
    try {
      final id = const Uuid().v4();
      final basePath = '${AppConstants.listingImagesPath}/$id';

      final heroUrl = await _uploadImage(heroImageFile, '$basePath/hero.jpg');

      final additionalUrls = await Future.wait([
        for (var i = 0; i < additionalImageFiles.length; i++)
          _uploadImage(additionalImageFiles[i], '$basePath/image_$i.jpg'),
      ]);

      final model = ListingModel(
        id: id,
        brokerUid: brokerUid,
        brokerName: brokerName,
        title: (title != null && title.isNotEmpty) ? title : null,
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
        heroImageUrl: heroUrl,
        additionalImageUrls: additionalUrls,
        brokerageAmount: brokerageAmount,
        posterRole: posterRole,
        visibility: visibility,
        status: ListingStatus.active,
        createdAt: DateTime.now(),
      );

      await _db
          .collection(AppConstants.listingsCollection)
          .doc(id)
          .set(model.toMap());

      return model;
    } catch (e) {
      throw ServerException('Failed to create listing: $e');
    }
  }

  @override
  Future<String> uploadPoster({
    required String listingId,
    required List<int> pngBytes,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('${AppConstants.postersPath}/$listingId/poster.jpg');
      final task = await ref.putData(
        Uint8List.fromList(pngBytes),
        SettableMetadata(contentType: 'image/png'),
      );
      final url = await task.ref.getDownloadURL();
      await _db
          .collection(AppConstants.listingsCollection)
          .doc(listingId)
          .update({'posterUrl': url});
      return url;
    } catch (e) {
      throw StorageException('Poster upload failed: $e');
    }
  }

  @override
  Future<List<ListingModel>> fetchListings({
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
      List<ListingModel> results;

      // brokerUids path: whereIn cannot be combined with orderBy on a different
      // field without a composite index, so skip ordering and cursor pagination.
      if (brokerUids != null && brokerUids.isNotEmpty) {
        final Query<Map<String, dynamic>> query = _db
            .collection(AppConstants.listingsCollection)
            .where('status', isEqualTo: 'active')
            .where('brokerUid', whereIn: brokerUids.take(30).toList())
            .limit(limit);
        final snap = await query.get();
        results = snap.docs.map((d) => ListingModel.fromFirestore(d)).toList();
      } else {
        Query<Map<String, dynamic>> query =
            _db.collection(AppConstants.listingsCollection)
                .where('status', isEqualTo: 'active');

        if (category != null) {
          query = query.where('category', isEqualTo: category.name);
        }
        if (propertyType != null) {
          query = query.where('propertyType', isEqualTo: propertyType.firestoreKey);
        }

        query = query.orderBy('createdAt', descending: true)
            .orderBy(FieldPath.documentId, descending: true)
            .limit(limit);

        if (lastCreatedAt != null && lastListingId != null) {
          query = query.startAfter([
            Timestamp.fromDate(lastCreatedAt),
            lastListingId,
          ]);
        }

        final snap = await query.get();
        results = snap.docs.map((d) => ListingModel.fromFirestore(d)).toList();
      }

      // Client-side filtering: visibility + optional city
      final isNetworkFeed = brokerUids != null;
      return results.where((l) {
        // Owner always sees their own listings
        if (currentUid != null && l.brokerUid == currentUid) {
          return city == null || city.isEmpty || l.city == city;
        }
        final visOk = switch (l.visibility) {
          ListingVisibility.all => true,
          ListingVisibility.network => isNetworkFeed,
          ListingVisibility.onlyMe => false,
        };
        if (!visOk) return false;
        return city == null || city.isEmpty || l.city == city;
      }).toList();
    } catch (e) {
      throw ServerException('Failed to fetch listings: $e');
    }
  }

  @override
  Future<List<ListingModel>> fetchBrokerListings(String brokerUid) async {
    try {
      final snap = await _db
          .collection(AppConstants.listingsCollection)
          .where('brokerUid', isEqualTo: brokerUid)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => ListingModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch broker listings: $e');
    }
  }

  @override
  Future<List<String>> fetchLikedListingIds(String uid) async {
    try {
      final snap = await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('likes')
          .get();
      return snap.docs.map((d) => d.id).toList();
    } catch (e) {
      throw ServerException('Failed to fetch liked listings: $e');
    }
  }

  @override
  Future<void> likeListing({
    required String listingId,
    required String uid,
  }) async {
    try {
      final batch = _db.batch();
      batch.set(
        _db
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .collection('likes')
            .doc(listingId),
        {'likedAt': FieldValue.serverTimestamp()},
      );
      batch.update(
        _db.collection(AppConstants.listingsCollection).doc(listingId),
        {'likesCount': FieldValue.increment(1)},
      );
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to like listing: $e');
    }
  }

  @override
  Future<void> unlikeListing({
    required String listingId,
    required String uid,
  }) async {
    try {
      final batch = _db.batch();
      batch.delete(
        _db
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .collection('likes')
            .doc(listingId),
      );
      batch.update(
        _db.collection(AppConstants.listingsCollection).doc(listingId),
        {'likesCount': FieldValue.increment(-1)},
      );
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to unlike listing: $e');
    }
  }

  @override
  Future<void> incrementView({
    required String listingId,
    required String uid,
  }) async {
    try {
      final batch = _db.batch();
      batch.set(
        _db
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .collection('views')
            .doc(listingId),
        {'viewedAt': FieldValue.serverTimestamp()},
      );
      batch.update(
        _db.collection(AppConstants.listingsCollection).doc(listingId),
        {'viewsCount': FieldValue.increment(1)},
      );
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to record view: $e');
    }
  }

  Future<String> _uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }
}
