import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
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
    String? instagramUrl,
    File? pdfFile,
    ListingVisibility visibility = ListingVisibility.all,
    double? originalPrice,
    void Function(double)? onProgress,
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

  Future<List<ListingModel>> fetchBrokerListings(
    String brokerUid, {
    DateTime? lastCreatedAt,
    String? lastDocId,
    int limit = 20,
  });

  /// Batch-checks whether [listingIds] appear in the user's `likes`
  /// subcollection. Returns a map of listingId → liked. Non-fatal: returns
  /// empty map on error so callers degrade gracefully.
  Future<Map<String, bool>> fetchLikedStatusBatch(
    String uid,
    List<String> listingIds,
  );

  /// Batch-checks whether [listingIds] appear in the user's `inquiries`
  /// subcollection. Returns a map of listingId → inquired. Non-fatal.
  Future<Map<String, bool>> fetchInquiredStatusBatch(
    String uid,
    List<String> listingIds,
  );

  /// Partial update of a listing's broker-editable fields. Caller is the
  /// listing owner; null parameters are left untouched.
  Future<void> updateListing({
    required String listingId,
    String? title,
    double? price,
    String? brokerageAmount,
    String? description,
  });

  Future<List<String>> fetchLikedListingIds(String uid);

  Future<void> likeListing({required String listingId, required String uid});

  Future<void> unlikeListing({required String listingId, required String uid});

  Future<List<String>> fetchInquiredListingIds(String uid);

  Future<void> recordInquiry({required String listingId, required String uid});

  Future<void> incrementView({required String listingId, required String uid});

  Future<void> deleteListing({required String listingId});

  Future<void> updateListingFull({
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
    String? instagramUrl,
    File? pdfFile,
    ListingVisibility visibility = ListingVisibility.all,
    double? originalPrice,
    void Function(double)? onProgress,
  }) async {
    try {
      final id = const Uuid().v4();
      final basePath = '${AppConstants.listingImagesPath}/$id';
      final totalFiles = 1 + additionalImageFiles.length + (pdfFile != null ? 1 : 0);
      var completed = 0;

      Future<String> uploadOne(File f, String p) async {
        final url = await _uploadImage(f, p);
        completed++;
        onProgress?.call(completed / totalFiles);
        return url;
      }

      // Upload hero + all additional images in parallel to reduce total wait time.
      final allFiles = [heroImageFile, ...additionalImageFiles];
      final allPaths = [
        '$basePath/hero.jpg',
        for (var i = 0; i < additionalImageFiles.length; i++)
          '$basePath/image_$i.jpg',
      ];
      final urls = await Future.wait([
        for (var i = 0; i < allFiles.length; i++)
          uploadOne(allFiles[i], allPaths[i]),
      ]);
      final heroUrl = urls[0];
      final additionalUrls = urls.sublist(1);

      String? pdfUrl;
      if (pdfFile != null) {
        pdfUrl = await _uploadPdf(pdfFile, '$basePath/document.pdf');
        completed++;
        onProgress?.call(completed / totalFiles);
      }

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
        instagramUrl: instagramUrl,
        pdfUrl: pdfUrl,
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
        Query<Map<String, dynamic>> query = _db
            .collection(AppConstants.listingsCollection)
            .where('status', isEqualTo: 'active');

        if (category != null) {
          query = query.where('category', isEqualTo: category.name);
        }
        if (propertyType != null) {
          query =
              query.where('propertyType', isEqualTo: propertyType.firestoreKey);
        }

        query = query
            .orderBy('createdAt', descending: true)
            .orderBy(FieldPath.documentId, descending: true)
            .limit(limit);

        if (lastCreatedAt != null && lastListingId != null) {
          // FieldPath.documentId cursor must be a full collection/docId path.
          query = query.startAfter([
            Timestamp.fromDate(lastCreatedAt),
            '${AppConstants.listingsCollection}/$lastListingId',
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
  Future<List<ListingModel>> fetchBrokerListings(
    String brokerUid, {
    DateTime? lastCreatedAt,
    String? lastDocId,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _db
          .collection(AppConstants.listingsCollection)
          .where('brokerUid', isEqualTo: brokerUid)
          .orderBy('createdAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(limit);
      if (lastCreatedAt != null && lastDocId != null) {
        query = query.startAfter([
          Timestamp.fromDate(lastCreatedAt),
          '${AppConstants.listingsCollection}/$lastDocId',
        ]);
      }
      final snap = await query.get();
      return snap.docs.map((d) => ListingModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch broker listings: $e');
    }
  }

  @override
  Future<Map<String, bool>> fetchLikedStatusBatch(
    String uid,
    List<String> listingIds,
  ) async {
    if (listingIds.isEmpty) return {};
    try {
      final ref = _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('likes');
      final docs = await Future.wait(listingIds.map((id) => ref.doc(id).get()));
      return {
        for (var i = 0; i < listingIds.length; i++) listingIds[i]: docs[i].exists,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Map<String, bool>> fetchInquiredStatusBatch(
    String uid,
    List<String> listingIds,
  ) async {
    if (listingIds.isEmpty) return {};
    try {
      final ref = _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('inquiries');
      final docs = await Future.wait(listingIds.map((id) => ref.doc(id).get()));
      return {
        for (var i = 0; i < listingIds.length; i++) listingIds[i]: docs[i].exists,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> updateListing({
    required String listingId,
    String? title,
    double? price,
    String? brokerageAmount,
    String? description,
  }) async {
    try {
      final patch = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (title != null) patch['title'] = title;
      if (price != null) patch['price'] = price;
      if (brokerageAmount != null) patch['brokerageAmount'] = brokerageAmount;
      if (description != null) patch['description'] = description;
      // Bail out cheaply if the caller passed nothing meaningful.
      if (patch.length == 1) return;
      await _db
          .collection(AppConstants.listingsCollection)
          .doc(listingId)
          .update(patch);
    } catch (e) {
      throw ServerException('Failed to update listing: $e');
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
  Future<List<String>> fetchInquiredListingIds(String uid) async {
    try {
      final snap = await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('inquiries')
          .get();
      return snap.docs.map((d) => d.id).toList();
    } catch (e) {
      throw ServerException('Failed to fetch inquired listings: $e');
    }
  }

  @override
  Future<void> recordInquiry({
    required String listingId,
    required String uid,
  }) async {
    try {
      await _db
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('inquiries')
          .doc(listingId)
          .set({'inquiredAt': FieldValue.serverTimestamp()});
    } catch (e) {
      throw ServerException('Failed to record inquiry: $e');
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

  @override
  Future<void> deleteListing({required String listingId}) async {
    try {
      await _db
          .collection(AppConstants.listingsCollection)
          .doc(listingId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete listing: $e');
    }
  }

  @override
  Future<void> updateListingFull({
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
      final basePath = '${AppConstants.listingImagesPath}/$listingId';
      final totalUploads = (newHeroImageFile != null ? 1 : 0) +
          newAdditionalImageFiles.length +
          (newPdfFile != null ? 1 : 0);
      var completed = 0;

      Future<String> uploadOne(File f, String p) async {
        final url = await _uploadImage(f, p);
        completed++;
        onProgress?.call(completed / totalUploads);
        return url;
      }

      final patch = <String, dynamic>{
        'category': category.name,
        'city': city,
        'location': location,
        'area': area,
        'areaUnit': areaUnit.name,
        'price': price,
        'visibility': visibility.name,
        'propertyType': propertyType?.firestoreKey,
        'title': (title != null && title.isNotEmpty) ? title : null,
        'originalPrice': originalPrice,
        'brokerageAmount':
            (brokerageAmount != null && brokerageAmount.isNotEmpty)
                ? brokerageAmount
                : null,
        'instagramUrl':
            (instagramUrl != null && instagramUrl.isNotEmpty)
                ? instagramUrl
                : null,
        'description':
            (description != null && description.isNotEmpty)
                ? description
                : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newHeroImageFile != null) {
        patch['heroImageUrl'] =
            await uploadOne(newHeroImageFile, '$basePath/hero.jpg');
      }

      if (newAdditionalImageFiles.isNotEmpty) {
        final newUrls = await Future.wait([
          for (var i = 0; i < newAdditionalImageFiles.length; i++)
            uploadOne(
              newAdditionalImageFiles[i],
              '$basePath/image_edit_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            ),
        ]);
        patch['additionalImageUrls'] = [...keptAdditionalImageUrls, ...newUrls];
      } else if (keptAdditionalImageUrls.isNotEmpty) {
        patch['additionalImageUrls'] = keptAdditionalImageUrls;
      } else {
        patch['additionalImageUrls'] = <String>[];
      }

      if (newPdfFile != null) {
        final pdfUrl =
            await _uploadPdf(newPdfFile, '$basePath/document.pdf');
        completed++;
        onProgress?.call(completed / (totalUploads > 0 ? totalUploads : 1));
        patch['pdfUrl'] = pdfUrl;
      } else {
        patch['pdfUrl'] = existingPdfUrl;
      }

      await _db
          .collection(AppConstants.listingsCollection)
          .doc(listingId)
          .update(patch);
    } catch (e) {
      throw ServerException('Failed to update listing: $e');
    }
  }

  Future<String> _uploadPdf(File file, String path) async {
    if (!file.existsSync()) {
      throw StorageException('PDF file not found: ${file.path}');
    }
    final ref = _storage.ref().child(path);
    final snapshot = await ref.putFile(
      file,
      SettableMetadata(contentType: 'application/pdf'),
    );
    if (snapshot.state != TaskState.success) {
      throw StorageException('PDF upload failed: $path');
    }
    return snapshot.ref.getDownloadURL();
  }

  Future<String> _uploadImage(File file, String path) async {
    if (!file.existsSync()) {
      throw StorageException('Image file not found: ${file.path}');
    }

    final toUpload = await _compressImage(file);

    final ref = _storage.ref().child(path);
    final snapshot = await ref.putFile(
      toUpload,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    if (toUpload.path != file.path) {
      try {
        toUpload.deleteSync();
      } catch (_) {}
    }

    if (snapshot.state != TaskState.success) {
      throw StorageException('Upload failed (state: ${snapshot.state}): $path');
    }

    return snapshot.ref.getDownloadURL();
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/${const Uuid().v4()}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: 75,
        minWidth: 1080,
        minHeight: 1,
        keepExif: false,
      );
      if (result != null) return File(result.path);
    } catch (_) {}
    return file;
  }
}
