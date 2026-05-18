import 'dart:io';
import 'package:dartz/dartz.dart';

import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/ask/data/datasources/ask_remote_datasource.dart';
import 'package:cpapp/features/ask/domain/entities/ask_comment.dart';
import 'package:cpapp/features/ask/domain/entities/ask_post.dart';
import 'package:cpapp/features/ask/domain/repositories/ask_repository.dart';

class AskRepositoryImpl implements AskRepository {
  const AskRepositoryImpl({required AskRemoteDataSource dataSource})
      : _ds = dataSource;

  final AskRemoteDataSource _ds;

  @override
  Stream<List<AskPost>> watchRecentPosts({int limit = 30}) =>
      _ds.watchRecentPosts(limit: limit);

  @override
  Future<Either<Failure, List<AskPost>>> fetchOlderPosts({
    required DateTime beforeCreatedAt,
    int limit = 30,
  }) async {
    try {
      final list = await _ds.fetchOlderPosts(
        beforeCreatedAt: beforeCreatedAt,
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
  Future<Either<Failure, AskPost>> createPost({
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
      final post = await _ds.createPost(
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
        imageFile: imageFile,
        imageAspectRatio: imageAspectRatio,
        isBold: isBold,
        textAlign: textAlign,
        backgroundColorHex: backgroundColorHex,
        fontSize: fontSize,
      );
      return Right(post);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePost(String postId) async {
    try {
      await _ds.deletePost(postId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePost({
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
      await _ds.updatePost(
        postId: postId,
        text: text,
        existingImageUrl: existingImageUrl,
        newImageFile: newImageFile,
        imageAspectRatio: imageAspectRatio,
        clearImage: clearImage,
        isBold: isBold,
        textAlign: textAlign,
        backgroundColorHex: backgroundColorHex,
        fontSize: fontSize,
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

  @override
  Future<Either<Failure, Unit>> reportPost({
    required String postId,
    required String reporterUid,
    required String reason,
  }) async {
    try {
      await _ds.reportPost(
        postId: postId,
        reporterUid: reporterUid,
        reason: reason,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleLike({
    required String postId,
    required String uid,
  }) async {
    try {
      await _ds.toggleLike(postId: postId, uid: uid);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> fetchLikedPostIds(String uid) async {
    try {
      return Right(await _ds.fetchLikedPostIds(uid));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  @override
  Stream<List<AskComment>> watchComments(String postId) =>
      _ds.watchComments(postId);

  @override
  Future<Either<Failure, AskComment>> addComment({
    required String postId,
    required String authorUid,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
  }) async {
    try {
      final c = await _ds.addComment(
        postId: postId,
        authorUid: authorUid,
        authorName: authorName,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
      );
      return Right(c);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateComment({
    required String postId,
    required String commentId,
    required String text,
  }) async {
    try {
      await _ds.updateComment(postId: postId, commentId: commentId, text: text);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      await _ds.deleteComment(postId: postId, commentId: commentId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
