import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/ask/data/models/ask_comment_model.dart';
import 'package:cpapp/features/ask/data/models/ask_post_model.dart';

abstract interface class AskRemoteDataSource {
  Stream<List<AskPostModel>> watchRecentPosts({int limit = 30});

  Future<List<AskPostModel>> fetchOlderPosts({
    required DateTime beforeCreatedAt,
    int limit = 30,
  });

  Future<AskPostModel> createPost({
    required String authorUid,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    File? imageFile,
    double? imageAspectRatio,
    bool isBold = false,
    String textAlign = 'left',
    String? backgroundColorHex,
    String fontSize = 'regular',
  });

  Future<void> deletePost(String postId);

  Future<void> updatePost({
    required String postId,
    required String text,
    String? existingImageUrl,
    File? newImageFile,
    double? imageAspectRatio,
    bool clearImage = false,
    bool isBold = false,
    String textAlign = 'left',
    String? backgroundColorHex,
    String fontSize = 'regular',
  });

  Future<void> reportPost({
    required String postId,
    required String reporterUid,
    required String reason,
  });

  Future<void> toggleLike({
    required String postId,
    required String uid,
  });

  Future<List<String>> fetchLikedPostIds(String uid);

  Stream<List<AskCommentModel>> watchComments(String postId);

  Future<AskCommentModel> addComment({
    required String postId,
    required String authorUid,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
  });

  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String text,
  });

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  });
}

class AskRemoteDataSourceImpl implements AskRemoteDataSource {
  AskRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _db = firestore,
        _storage = storage;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection(AppConstants.postsCollection);

  // ── Posts ───────────────────────────────────────────────────────────────────

  @override
  Stream<List<AskPostModel>> watchRecentPosts({int limit = 30}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AskPostModel.fromFirestore(d)).toList(),);
  }

  @override
  Future<List<AskPostModel>> fetchOlderPosts({
    required DateTime beforeCreatedAt,
    int limit = 30,
  }) async {
    try {
      final snap = await _posts
          .orderBy('createdAt', descending: true)
          .startAfter([Timestamp.fromDate(beforeCreatedAt)])
          .limit(limit)
          .get();
      return snap.docs.map((d) => AskPostModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch older posts: $e');
    }
  }

  @override
  Future<AskPostModel> createPost({
    required String authorUid,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    File? imageFile,
    double? imageAspectRatio,
    bool isBold = false,
    String textAlign = 'left',
    String? backgroundColorHex,
    String fontSize = 'regular',
  }) async {
    try {
      final docRef = _posts.doc();
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(
          file: imageFile,
          path: 'posts/${docRef.id}/${const Uuid().v4()}.jpg',
        );
      }
      final now = DateTime.now();
      final model = AskPostModel(
        id: docRef.id,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
        imageUrl: imageUrl,
        likesCount: 0,
        commentsCount: 0,
        createdAt: now,
        isBold: isBold,
        textAlign: textAlign,
        backgroundColorHex: backgroundColorHex,
        fontSize: fontSize,
        imageAspectRatio: imageAspectRatio,
      );
      await docRef.set({
        ...model.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return model;
    } on StorageException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create post: $e');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await _posts.doc(postId).delete();
    } catch (e) {
      throw ServerException('Failed to delete post: $e');
    }
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String text,
    String? existingImageUrl,
    File? newImageFile,
    double? imageAspectRatio,
    bool clearImage = false,
    bool isBold = false,
    String textAlign = 'left',
    String? backgroundColorHex,
    String fontSize = 'regular',
  }) async {
    try {
      String? imageUrl;
      if (newImageFile != null) {
        imageUrl = await _uploadImage(
          file: newImageFile,
          path: 'posts/$postId/${const Uuid().v4()}.jpg',
        );
      } else if (!clearImage) {
        imageUrl = existingImageUrl;
      }

      await _posts.doc(postId).update({
        'text': text,
        'imageUrl': imageUrl,
        'isBold': isBold,
        'textAlign': textAlign,
        'backgroundColorHex': backgroundColorHex,
        'fontSize': fontSize,
        'updatedAt': FieldValue.serverTimestamp(),
        if (imageAspectRatio != null) 'imageAspectRatio': imageAspectRatio,
        if (clearImage) 'imageAspectRatio': FieldValue.delete(),
      });
    } on StorageException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to update post: $e');
    }
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reporterUid,
    required String reason,
  }) async {
    try {
      await _posts.doc(postId).collection('reports').doc(reporterUid).set({
        'reason': reason,
        'reporterUid': reporterUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to report post: $e');
    }
  }

  // ── Likes ───────────────────────────────────────────────────────────────────

  @override
  Future<void> toggleLike({
    required String postId,
    required String uid,
  }) async {
    final postRef = _posts.doc(postId);
    final likeRef = postRef.collection('likes').doc(uid);
    try {
      await _db.runTransaction((tx) async {
        final likeSnap = await tx.get(likeRef);
        if (likeSnap.exists) {
          tx.delete(likeRef);
          tx.update(postRef, {'likesCount': FieldValue.increment(-1)});
        } else {
          tx.set(likeRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
          tx.update(postRef, {'likesCount': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      throw ServerException('Failed to toggle like: $e');
    }
  }

  @override
  Future<List<String>> fetchLikedPostIds(String uid) async {
    try {
      final snap = await _db
          .collectionGroup('likes')
          .where('uid', isEqualTo: uid)
          .limit(500)
          .get();
      return snap.docs
          .map((d) => d.reference.parent.parent?.id)
          .whereType<String>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch liked posts: $e');
    }
  }

  // ── Comments ────────────────────────────────────────────────────────────────

  @override
  Stream<List<AskCommentModel>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection(AppConstants.commentsCollection)
        .orderBy('createdAt', descending: false)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AskCommentModel.fromFirestore(d, postId))
            .toList(),);
  }

  @override
  Future<AskCommentModel> addComment({
    required String postId,
    required String authorUid,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
  }) async {
    try {
      final postRef = _posts.doc(postId);
      final commentRef =
          postRef.collection(AppConstants.commentsCollection).doc();
      final now = DateTime.now();
      final model = AskCommentModel(
        id: commentRef.id,
        postId: postId,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
        createdAt: now,
      );
      // Atomic: write comment + bump counter together.
      final batch = _db.batch();
      batch.set(commentRef, {
        ...model.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(postRef, {'commentsCount': FieldValue.increment(1)});
      await batch.commit();
      return model;
    } catch (e) {
      throw ServerException('Failed to add comment: $e');
    }
  }

  @override
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    try {
      await _posts
          .doc(postId)
          .collection(AppConstants.commentsCollection)
          .doc(commentId)
          .update({
        'text': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to update comment: $e');
    }
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final postRef = _posts.doc(postId);
      final commentRef = postRef
          .collection(AppConstants.commentsCollection)
          .doc(commentId);
      final batch = _db.batch();
      batch.delete(commentRef);
      batch.update(postRef, {'commentsCount': FieldValue.increment(-1)});
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to delete comment: $e');
    }
  }

  // ── Image upload helpers ───────────────────────────────────────────────────

  Future<String> _uploadImage({
    required File file,
    required String path,
  }) async {
    if (!file.existsSync()) {
      throw StorageException('Image file not found: ${file.path}');
    }
    final compressed = await _compressImage(file);
    final ref = _storage.ref().child(path);
    final snapshot = await ref.putFile(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    if (compressed.path != file.path) {
      try {
        compressed.deleteSync();
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
      // No forced dimensions — preserve original aspect ratio.
      // ImagePicker already caps at 2160px, so just quality-compress here.
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: 75,
        minWidth: 1080,
        minHeight: 1350,
        keepExif: false,
      );
      if (result != null) return File(result.path);
    } catch (_) {}
    return file;
  }
}
