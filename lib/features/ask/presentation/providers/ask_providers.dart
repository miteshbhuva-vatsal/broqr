import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cpapp/features/ask/data/datasources/ask_remote_datasource.dart';
import 'package:cpapp/features/ask/data/repositories/ask_repository_impl.dart';
import 'package:cpapp/features/ask/domain/entities/ask_comment.dart';
import 'package:cpapp/features/ask/domain/entities/ask_post.dart';
import 'package:cpapp/features/ask/domain/repositories/ask_repository.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final askRemoteDataSourceProvider = Provider<AskRemoteDataSource>((ref) {
  return AskRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final askRepositoryProvider = Provider<AskRepository>((ref) {
  return AskRepositoryImpl(dataSource: ref.watch(askRemoteDataSourceProvider));
});

// ── Feed state ────────────────────────────────────────────────────────────────

class AskFeedState {
  AskFeedState({
    this.streamPosts = const [],
    this.olderPosts = const [],
    this.likedIds = const {},
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  /// Live tail (newest first).
  final List<AskPost> streamPosts;

  /// Paginated older pages (newest-of-older first to keep merged order).
  final List<AskPost> olderPosts;

  final Set<String> likedIds;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  late final List<AskPost> posts = _merge();

  List<AskPost> _merge() {
    if (olderPosts.isEmpty) return streamPosts;
    final ids = {for (final p in streamPosts) p.id};
    final dedup = olderPosts.where((p) => !ids.contains(p.id));
    return [...streamPosts, ...dedup];
  }

  bool isLiked(String postId) => likedIds.contains(postId);

  AskFeedState copyWith({
    List<AskPost>? streamPosts,
    List<AskPost>? olderPosts,
    Set<String>? likedIds,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return AskFeedState(
      streamPosts: streamPosts ?? this.streamPosts,
      olderPosts: olderPosts ?? this.olderPosts,
      likedIds: likedIds ?? this.likedIds,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AskFeedNotifier extends StateNotifier<AskFeedState> {
  AskFeedNotifier(this._ref) : super(AskFeedState()) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<List<AskPost>>? _sub;

  AskRepository get _repo => _ref.read(askRepositoryProvider);

  String? get _uid => _ref.read(authStateChangesProvider).valueOrNull?.uid;

  Future<void> _init() async {
    // Hydrate liked ids first so the heart state lights up correctly when
    // posts stream in.
    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      final liked = await _repo.fetchLikedPostIds(uid);
      liked.fold(
        (_) {},
        (ids) => state = state.copyWith(likedIds: ids.toSet()),
      );
    }
    _sub = _repo.watchRecentPosts().listen(
          (posts) => state = state.copyWith(
            streamPosts: posts,
            isLoading: false,
            clearError: true,
          ),
          onError: (Object e) => state = state.copyWith(
            isLoading: false,
            error: e.toString(),
          ),
        );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      olderPosts: const [],
      hasMore: true,
      clearError: true,
    );
    // Re-hydrate liked ids; stream is already live so re-subscribing is wasteful.
    final uid = _uid;
    if (uid != null && uid.isNotEmpty) {
      final liked = await _repo.fetchLikedPostIds(uid);
      liked.fold(
        (_) {},
        (ids) => state = state.copyWith(likedIds: ids.toSet()),
      );
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadOlder() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final cursor =
        state.posts.isEmpty ? null : state.posts.last.createdAt;
    if (cursor == null) return;
    state = state.copyWith(isLoadingMore: true);
    const pageSize = 30;
    final result = await _repo.fetchOlderPosts(
      beforeCreatedAt: cursor,
      limit: pageSize,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      ),
      (older) => state = state.copyWith(
        isLoadingMore: false,
        olderPosts: [...state.olderPosts, ...older],
        hasMore: older.length >= pageSize,
      ),
    );
  }

  Future<bool> createPost({
    required String text,
    File? imageFile,
    double? imageAspectRatio,
    bool isBold = false,
    String textAlign = 'left',
    String? backgroundColorHex,
    String fontSize = 'regular',
  }) async {
    final user = _ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return false;
    final result = await _repo.createPost(
      authorUid: user.uid,
      authorName: user.name,
      authorPhotoUrl: user.photoUrl,
      text: text.trim(),
      imageFile: imageFile,
      imageAspectRatio: imageAspectRatio,
      isBold: isBold,
      textAlign: textAlign,
      backgroundColorHex: backgroundColorHex,
      fontSize: fontSize,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Stream will deliver the new post; no explicit insert needed.
        return true;
      },
    );
  }

  Future<bool> updatePost({
    required AskPost post,
    required String text,
    File? newImageFile,
    double? imageAspectRatio,
    bool clearImage = false,
    bool isBold = false,
    String textAlign = 'left',
    String? backgroundColorHex,
    String fontSize = 'regular',
  }) async {
    // Optimistic update in the feed.
    final optimistic = post.copyWith(
      text: text,
      isBold: isBold,
      textAlign: textAlign,
      backgroundColorHex: backgroundColorHex,
      clearBackground: backgroundColorHex == null,
      clearImage: clearImage,
    );
    state = state.copyWith(
      streamPosts: state.streamPosts.map((p) => p.id == post.id ? optimistic : p).toList(),
      olderPosts: state.olderPosts.map((p) => p.id == post.id ? optimistic : p).toList(),
    );

    final result = await _repo.updatePost(
      postId: post.id,
      text: text.trim(),
      existingImageUrl: post.imageUrl,
      newImageFile: newImageFile,
      imageAspectRatio: imageAspectRatio,
      clearImage: clearImage,
      isBold: isBold,
      textAlign: textAlign,
      backgroundColorHex: backgroundColorHex,
      fontSize: fontSize,
    );
    return result.fold(
      (failure) {
        // Revert on failure.
        state = state.copyWith(
          streamPosts: state.streamPosts.map((p) => p.id == post.id ? post : p).toList(),
          olderPosts: state.olderPosts.map((p) => p.id == post.id ? post : p).toList(),
          error: failure.message,
        );
        return false;
      },
      (_) => true,
    );
  }

  Future<void> deletePost(String postId) async {
    // Optimistic local removal — stream will reconcile.
    state = state.copyWith(
      streamPosts:
          state.streamPosts.where((p) => p.id != postId).toList(),
      olderPosts: state.olderPosts.where((p) => p.id != postId).toList(),
    );
    final result = await _repo.deletePost(postId);
    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {},
    );
  }

  Future<void> toggleLike(String postId) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;

    // Optimistic flip of liked set + counter.
    final wasLiked = state.likedIds.contains(postId);
    final newLikedIds = Set<String>.from(state.likedIds);
    if (wasLiked) {
      newLikedIds.remove(postId);
    } else {
      newLikedIds.add(postId);
    }
    final delta = wasLiked ? -1 : 1;
    state = state.copyWith(
      likedIds: newLikedIds,
      streamPosts: state.streamPosts
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    likesCount: (p.likesCount + delta).clamp(0, 1 << 30),
                  )
                : p,
          )
          .toList(),
      olderPosts: state.olderPosts
          .map(
            (p) => p.id == postId
                ? p.copyWith(
                    likesCount: (p.likesCount + delta).clamp(0, 1 << 30),
                  )
                : p,
          )
          .toList(),
    );

    final result = await _repo.toggleLike(postId: postId, uid: uid);
    result.fold(
      (failure) {
        // Revert on failure.
        state = state.copyWith(
          likedIds: wasLiked
              ? (Set<String>.from(state.likedIds)..add(postId))
              : (Set<String>.from(state.likedIds)..remove(postId)),
          error: failure.message,
        );
      },
      (_) {},
    );
  }

  Future<bool> reportPost({
    required String postId,
    required String reason,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return false;
    final result = await _repo.reportPost(
      postId: postId,
      reporterUid: uid,
      reason: reason,
    );
    return result.fold((_) => false, (_) => true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final askFeedProvider =
    StateNotifierProvider<AskFeedNotifier, AskFeedState>((ref) {
  return AskFeedNotifier(ref);
});

// ── Per-post comments stream ──────────────────────────────────────────────────

final askCommentsProvider =
    StreamProvider.family<List<AskComment>, String>((ref, postId) {
  return ref.watch(askRepositoryProvider).watchComments(postId);
});
