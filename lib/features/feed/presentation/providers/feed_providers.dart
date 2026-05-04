import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/broker_network/presentation/providers/network_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';

part 'feed_providers.g.dart';

// ── Feed mode ─────────────────────────────────────────────────────────────────

enum FeedMode { all, network, mine }

// ── Feed state ────────────────────────────────────────────────────────────────

class FeedState {
  const FeedState({
    this.listings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.categoryFilter,
    this.propertyTypeFilter,
    this.cityFilter,
    this.likedIds = const {},
    this.viewedIds = const {},
    this.mode = FeedMode.all,
    this.error,
  });

  final List<Listing> listings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ListingCategory? categoryFilter;
  final PropertyType? propertyTypeFilter;
  /// Non-null, non-empty string = filter by city. Null or empty = all cities.
  final String? cityFilter;
  final Set<String> likedIds;
  final Set<String> viewedIds;
  final FeedMode mode;
  final String? error;

  int get activeFilterCount =>
      (categoryFilter != null ? 1 : 0) + (propertyTypeFilter != null ? 1 : 0);

  bool isLiked(String listingId) => likedIds.contains(listingId);

  FeedState copyWith({
    List<Listing>? listings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    ListingCategory? categoryFilter,
    bool clearCategory = false,
    PropertyType? propertyTypeFilter,
    bool clearPropertyType = false,
    String? cityFilter,
    bool clearCity = false,
    Set<String>? likedIds,
    Set<String>? viewedIds,
    FeedMode? mode,
    String? error,
    bool clearError = false,
  }) {
    return FeedState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      propertyTypeFilter: clearPropertyType
          ? null
          : (propertyTypeFilter ?? this.propertyTypeFilter),
      cityFilter: clearCity ? null : (cityFilter ?? this.cityFilter),
      likedIds: likedIds ?? this.likedIds,
      viewedIds: viewedIds ?? this.viewedIds,
      mode: mode ?? this.mode,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Feed notifier ─────────────────────────────────────────────────────────────

@riverpod
class Feed extends _$Feed {
  static const int _pageSize = AppConstants.feedPageSize;

  DateTime? _lastLoadMoreAt;

  @override
  FeedState build() {
    final city = ref.watch(cityPreferenceProvider);
    Future.microtask(() => _loadFirstPage());
    return FeedState(isLoading: true, cityFilter: city);
  }

  // ── Internal loaders ───────────────────────────────────────────────────────

  Future<void> _loadFirstPage() async {
    final repo = ref.read(listingRepositoryProvider);
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';

    List<String>? brokerUids;
    if (state.mode == FeedMode.network) {
      final connectedUids = ref.read(connectedUidsProvider);
      if (connectedUids.isEmpty) {
        state = state.copyWith(isLoading: false, listings: [], hasMore: false);
        return;
      }
      brokerUids = connectedUids;
    } else if (state.mode == FeedMode.mine) {
      if (uid.isEmpty) {
        state = state.copyWith(isLoading: false, listings: [], hasMore: false);
        return;
      }
      brokerUids = [uid];
    }

    final likedFuture = repo.fetchLikedListingIds(uid);
    final listingsFuture = repo.fetchListings(
      category: state.categoryFilter,
      propertyType: state.propertyTypeFilter,
      limit: _pageSize,
      brokerUids: brokerUids,
      currentUid: uid,
      city: state.cityFilter,
    );

    final likedResult = await likedFuture;
    final listingsResult = await listingsFuture;

    final likedIds = likedResult.fold(
      (_) => state.likedIds,
      (ids) => ids.toSet(),
    );

    listingsResult.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        likedIds: likedIds,
        error: failure.message,
      ),
      (listings) => state = state.copyWith(
        isLoading: false,
        clearError: true,
        listings: listings,
        likedIds: likedIds,
        hasMore: listings.length >= _pageSize,
      ),
    );
  }

  Future<void> _loadNextPage() async {
    final last = state.listings.isNotEmpty ? state.listings.last : null;
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';

    List<String>? brokerUids;
    if (state.mode == FeedMode.network) {
      brokerUids = ref.read(connectedUidsProvider);
    } else if (state.mode == FeedMode.mine) {
      brokerUids = [uid];
    }

    final result = await ref.read(listingRepositoryProvider).fetchListings(
          category: state.categoryFilter,
          propertyType: state.propertyTypeFilter,
          lastCreatedAt: last?.createdAt,
          lastListingId: last?.id,
          limit: _pageSize,
          brokerUids: brokerUids,
          currentUid: uid,
          city: state.cityFilter,
        );

    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        error: failure.message,
      ),
      (more) => state = state.copyWith(
        isLoadingMore: false,
        listings: [...state.listings, ...more],
        hasMore: more.length >= _pageSize,
      ),
    );
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = FeedState(
      isLoading: true,
      categoryFilter: state.categoryFilter,
      propertyTypeFilter: state.propertyTypeFilter,
      cityFilter: state.cityFilter,
      mode: state.mode,
      likedIds: state.likedIds,
    );
    await _loadFirstPage();
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastLoadMoreAt = now;
    state = state.copyWith(isLoadingMore: true);
    await _loadNextPage();
  }

  void setFeedMode(FeedMode mode) {
    if (state.mode == mode) return;
    state = FeedState(
      isLoading: true,
      categoryFilter: state.categoryFilter,
      propertyTypeFilter: state.propertyTypeFilter,
      cityFilter: state.cityFilter,
      mode: mode,
      likedIds: state.likedIds,
    );
    Future.microtask(() => _loadFirstPage());
  }

  void applyFilters({
    ListingCategory? category,
    PropertyType? propertyType,
    bool clearCategory = false,
    bool clearPropertyType = false,
  }) {
    final newCat = clearCategory ? null : (category ?? state.categoryFilter);
    final newPt = clearPropertyType ? null : (propertyType ?? state.propertyTypeFilter);
    if (newCat == state.categoryFilter && newPt == state.propertyTypeFilter) {
      return;
    }
    state = FeedState(
      isLoading: true,
      categoryFilter: newCat,
      propertyTypeFilter: newPt,
      cityFilter: state.cityFilter,
      mode: state.mode,
      likedIds: state.likedIds,
    );
    Future.microtask(() => _loadFirstPage());
  }

  Future<void> toggleLike(Listing listing) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final wasLiked = state.likedIds.contains(listing.id);

    final newLikedIds = Set<String>.from(state.likedIds);
    if (wasLiked) {
      newLikedIds.remove(listing.id);
    } else {
      newLikedIds.add(listing.id);
    }

    final newListings = state.listings.map((l) {
      if (l.id != listing.id) return l;
      return l.copyWith(
        likesCount: wasLiked
            ? (l.likesCount - 1).clamp(0, 999999)
            : l.likesCount + 1,
      );
    }).toList();

    state = state.copyWith(listings: newListings, likedIds: newLikedIds);

    final repo = ref.read(listingRepositoryProvider);
    if (wasLiked) {
      await repo.unlikeListing(listingId: listing.id, uid: uid);
    } else {
      await repo.likeListing(listingId: listing.id, uid: uid);
    }
  }

  Future<void> trackView(Listing listing) async {
    if (state.viewedIds.contains(listing.id)) return;
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    state = state.copyWith(
      viewedIds: {...state.viewedIds, listing.id},
    );

    await ref.read(listingRepositoryProvider).incrementView(
          listingId: listing.id,
          uid: uid,
        );
  }
}
