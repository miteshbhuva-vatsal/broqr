import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/ask/domain/entities/ask_comment.dart';
import 'package:cpapp/features/ask/domain/entities/ask_post.dart';

abstract interface class AskRepository {
  /// Live stream of the most recent [limit] community posts (newest first).
  Stream<List<AskPost>> watchRecentPosts({int limit = 30});

  /// One-shot pagination: fetch posts strictly older than [beforeCreatedAt].
  Future<Either<Failure, List<AskPost>>> fetchOlderPosts({
    required DateTime beforeCreatedAt,
    int limit = 30,
  });

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
  });

  Future<Either<Failure, Unit>> deletePost(String postId);

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
  });

  Future<Either<Failure, Unit>> reportPost({
    required String postId,
    required String reporterUid,
    required String reason,
  });

  /// Toggles the current user's like on the post and bumps the counter.
  Future<Either<Failure, Unit>> toggleLike({
    required String postId,
    required String uid,
  });

  /// Returns the post ids the current user has liked (for hydrating UI).
  Future<Either<Failure, List<String>>> fetchLikedPostIds(String uid);

  // ── Comments ──────────────────────────────────────────────────────────────

  Stream<List<AskComment>> watchComments(String postId);

  Future<Either<Failure, AskComment>> addComment({
    required String postId,
    required String authorUid,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
  });

  Future<Either<Failure, Unit>> updateComment({
    required String postId,
    required String commentId,
    required String text,
  });

  Future<Either<Failure, Unit>> deleteComment({
    required String postId,
    required String commentId,
  });
}
