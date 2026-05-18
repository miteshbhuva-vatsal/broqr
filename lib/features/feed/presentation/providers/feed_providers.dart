import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/listing/domain/repositories/listing_repository.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';

part 'feed_providers.g.dart';

// ── Feed mode ─────────────────────────────────────────────────────────────────

enum FeedMode { all, mine, inquired }

// ── Feed state ────────────────────────────────────────────────────────────────

class FeedState {
  FeedState({
    this.listings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.categoryFilter,
    this.propertyTypeFilter,
    this.cityFilter,
    this.likedIds = const {},
    this.contactedIds = const {},
    this.mode = FeedMode.all,
    this.searchQuery = '',
    this.error,
    this.orgRestrictedUid,
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
  final Set<String> contactedIds;
  final FeedMode mode;

  /// Non-null when an org admin has restricted team members to see only their
  /// own listings. Contains the admin's UID used as a brokerUids filter.
  final String? orgRestrictedUid;

  /// Free-text search across loaded listings. Filtering is local to the
  /// already-fetched page set; older listings beyond the loaded window won't
  /// surface until the user paginates further. Empty = show everything.
  final String searchQuery;

  final String? error;

  int get activeFilterCount =>
      (categoryFilter != null ? 1 : 0) + (propertyTypeFilter != null ? 1 : 0);

  bool isLiked(String listingId) => likedIds.contains(listingId);
  bool isContacted(String listingId) => contactedIds.contains(listingId);

  /// Listings the UI should render — `listings` filtered by [searchQuery].
  /// Multi-word queries require every token to appear somewhere in the
  /// listing's combined haystack (case-insensitive substring).
  late final List<Listing> visibleListings = _applySearch();

  List<Listing> _applySearch() {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return listings;
    final tokens =
        q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return listings;
    return listings.where((l) {
      final haystack = [
        l.title ?? '',
        l.description ?? '',
        l.city,
        l.location,
        l.brokerName,
        l.brokerageAmount ?? '',
        l.priceLabel,
        l.category.label,
        l.propertyType?.label ?? '',
      ].join(' ').toLowerCase();
      return tokens.every(haystack.contains);
    }).toList();
  }

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
    Set<String>? contactedIds,
    FeedMode? mode,
    String? searchQuery,
    String? error,
    bool clearError = false,
    String? orgRestrictedUid,
    bool clearOrgRestriction = false,
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
      contactedIds: contactedIds ?? this.contactedIds,
      mode: mode ?? this.mode,
      searchQuery: searchQuery ?? this.searchQuery,
      error: clearError ? null : (error ?? this.error),
      orgRestrictedUid: clearOrgRestriction
          ? null
          : (orgRestrictedUid ?? this.orgRestrictedUid),
    );
  }
}

// ── Feed notifier ─────────────────────────────────────────────────────────────

@riverpod
class Feed extends _$Feed {
  static const int _pageSize = AppConstants.feedPageSize;

  DateTime? _lastLoadMoreAt;
  // Tracks viewed IDs in-memory only — no state update so no list rebuild.
  final Set<String> _viewedIds = {};

  @override
  FeedState build() {
    final city = ref.watch(cityPreferenceProvider);
    final orgRestrictedUid = ref.watch(orgFeedRestrictionProvider);
    bool cancelled = false;
    ref.onDispose(() => cancelled = true);
    Future.microtask(() {
      if (!cancelled) _loadFirstPage();
    });
    return FeedState(
      isLoading: true,
      cityFilter: city,
      orgRestrictedUid: orgRestrictedUid,
    );
  }

  // ── Internal loaders ───────────────────────────────────────────────────────

  Future<void> _loadFirstPage() async {
    final repo = ref.read(listingRepositoryProvider);
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';

    List<String>? brokerUids;
    if (state.orgRestrictedUid != null) {
      brokerUids = [state.orgRestrictedUid!];
    } else if (state.mode == FeedMode.mine) {
      if (uid.isEmpty) {
        state = state.copyWith(isLoading: false, listings: [], hasMore: false);
        return;
      }
      brokerUids = [uid];
    }

    final listingsResult = await repo.fetchListings(
      category: state.categoryFilter,
      propertyType: state.propertyTypeFilter,
      limit: _pageSize,
      brokerUids: brokerUids,
      currentUid: uid,
      city: state.cityFilter,
    );

    List<Listing>? listings;
    String? loadError;
    listingsResult.fold((f) => loadError = f.message, (l) => listings = l);

    if (loadError != null) {
      state = state.copyWith(isLoading: false, error: loadError);
      return;
    }

    final page = listings!;
    final (likedIds, contactedIds) =
        await _batchStatusForPage(uid, page, state.likedIds, state.contactedIds, repo);

    state = state.copyWith(
      isLoading: false,
      clearError: true,
      listings: page,
      likedIds: likedIds,
      contactedIds: contactedIds,
      hasMore: page.length >= _pageSize,
    );
  }

  /// Batch-fetches like and inquired status only for [page]'s listing IDs,
  /// merges the results into the existing sets, and returns the updated pair.
  Future<(Set<String>, Set<String>)> _batchStatusForPage(
    String uid,
    List<Listing> page,
    Set<String> existingLiked,
    Set<String> existingContacted,
    ListingRepository repo,
  ) async {
    if (uid.isEmpty || page.isEmpty) return (existingLiked, existingContacted);
    final ids = page.map((l) => l.id).toList();
    final results = await Future.wait([
      repo.fetchLikedStatusBatch(uid, ids),
      repo.fetchInquiredStatusBatch(uid, ids),
    ]);
    final likedMap     = results[0].fold((_) => <String, bool>{}, (m) => m);
    final contactedMap = results[1].fold((_) => <String, bool>{}, (m) => m);
    return (
      _mergeStatusSet(existingLiked, likedMap),
      _mergeStatusSet(existingContacted, contactedMap),
    );
  }

  static Set<String> _mergeStatusSet(
    Set<String> existing,
    Map<String, bool> statusMap,
  ) {
    if (statusMap.isEmpty) return existing;
    final updated = Set<String>.from(existing);
    for (final entry in statusMap.entries) {
      if (entry.value) {
        updated.add(entry.key);
      } else {
        updated.remove(entry.key);
      }
    }
    return updated;
  }

  /// Marks a listing as inquired in both local state and Firestore.
  Future<void> markInquired(String listingId) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) return;
    final newIds = Set<String>.from(state.contactedIds)..add(listingId);
    state = state.copyWith(contactedIds: newIds);
    await ref.read(listingRepositoryProvider).recordInquiry(
      listingId: listingId,
      uid: uid,
    );
  }

  Future<void> _loadNextPage() async {
    final last = state.listings.isNotEmpty ? state.listings.last : null;
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    final repo = ref.read(listingRepositoryProvider);

    List<String>? brokerUids;
    if (state.orgRestrictedUid != null) {
      brokerUids = [state.orgRestrictedUid!];
    } else if (state.mode == FeedMode.mine) {
      brokerUids = [uid];
    }

    final result = await repo.fetchListings(
      category: state.categoryFilter,
      propertyType: state.propertyTypeFilter,
      lastCreatedAt: last?.createdAt,
      lastListingId: last?.id,
      limit: _pageSize,
      brokerUids: brokerUids,
      currentUid: uid,
      city: state.cityFilter,
    );

    List<Listing>? more;
    String? loadError;
    result.fold((f) => loadError = f.message, (l) => more = l);

    if (loadError != null) {
      state = state.copyWith(isLoadingMore: false, error: loadError);
      return;
    }

    final page = more!;
    final (likedIds, contactedIds) =
        await _batchStatusForPage(uid, page, state.likedIds, state.contactedIds, repo);

    state = state.copyWith(
      isLoadingMore: false,
      listings: [...state.listings, ...page],
      likedIds: likedIds,
      contactedIds: contactedIds,
      hasMore: page.length >= _pageSize,
    );
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  Future<void> refresh() async {
    _viewedIds.clear();
    state = FeedState(
      isLoading: true,
      categoryFilter: state.categoryFilter,
      propertyTypeFilter: state.propertyTypeFilter,
      cityFilter: state.cityFilter,
      mode: state.mode,
      likedIds: state.likedIds,
      searchQuery: state.searchQuery,
      orgRestrictedUid: state.orgRestrictedUid,
    );
    await _loadFirstPage();
  }

  /// Update the search query. Filtering is local — no network call. Stored on
  /// state so it survives mode/filter switches and so derived widgets can
  /// observe it via `select`.
  void setSearchQuery(String q) {
    if (q == state.searchQuery) return;
    state = state.copyWith(searchQuery: q);
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
    // Inquired tab uses inquiredListingsProvider — no feed load needed.
    if (mode == FeedMode.inquired) {
      state = state.copyWith(mode: mode);
      return;
    }
    // Switching away from inquired back to all/mine needs a real load.
    state = FeedState(
      isLoading: true,
      categoryFilter: state.categoryFilter,
      propertyTypeFilter: state.propertyTypeFilter,
      cityFilter: state.cityFilter,
      mode: mode,
      likedIds: state.likedIds,
      contactedIds: state.contactedIds,
      searchQuery: state.searchQuery,
      orgRestrictedUid: state.orgRestrictedUid,
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
      searchQuery: state.searchQuery,
      orgRestrictedUid: state.orgRestrictedUid,
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
    if (_viewedIds.contains(listing.id)) return;
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;
    _viewedIds.add(listing.id); // local-only — no state rebuild
    await ref.read(listingRepositoryProvider).incrementView(
          listingId: listing.id,
          uid: uid,
        );
  }
}
