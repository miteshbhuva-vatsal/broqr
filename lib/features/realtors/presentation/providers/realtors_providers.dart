import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/features/auth/data/models/user_model.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

part 'realtors_providers.g.dart';

// ── Realtors state ────────────────────────────────────────────────────────────

class RealtorsState {
  RealtorsState({
    this.realtors = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.searchQuery = '',
    this.cityFilter,
    this.accountTypeFilter,
    this.categoryFilter,
    this.error,
  });

  final List<AppUser> realtors;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String searchQuery;

  /// Non-null = filter by this city.
  final String? cityFilter;

  /// 'individual' | 'organisation' | null (all).
  final String? accountTypeFilter;

  /// ListingCategory name (e.g. 'residential') — client-side filter.
  final String? categoryFilter;

  final String? error;

  int get activeFilterCount =>
      (cityFilter != null ? 1 : 0) +
      (accountTypeFilter != null ? 1 : 0) +
      (categoryFilter != null ? 1 : 0);

  late final List<AppUser> visible = _apply();

  List<AppUser> _apply() {
    var list = realtors;
    if (accountTypeFilter != null) {
      list = list.where((u) => u.accountType == accountTypeFilter).toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return list;
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    return list.where((u) {
      final hay = [
        u.name,
        u.city ?? '',
        u.companyName ?? '',
        u.role?.name ?? '',
        u.accountType,
      ].join(' ').toLowerCase();
      return tokens.every(hay.contains);
    }).toList();
  }

  RealtorsState copyWith({
    List<AppUser>? realtors,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? searchQuery,
    String? cityFilter,
    bool clearCity = false,
    String? accountTypeFilter,
    bool clearAccountType = false,
    String? categoryFilter,
    bool clearCategory = false,
    String? error,
    bool clearError = false,
  }) {
    return RealtorsState(
      realtors: realtors ?? this.realtors,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      cityFilter: clearCity ? null : (cityFilter ?? this.cityFilter),
      accountTypeFilter: clearAccountType
          ? null
          : (accountTypeFilter ?? this.accountTypeFilter),
      categoryFilter:
          clearCategory ? null : (categoryFilter ?? this.categoryFilter),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Realtors notifier ─────────────────────────────────────────────────────────

@riverpod
class Realtors extends _$Realtors {
  static const _pageSize = 20;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  RealtorsState build() {
    // Mirror the feed pattern: watch the saved city preference so the tab
    // auto-loads with the user's default city and rebuilds if they change it.
    final prefCity = ref.watch(cityPreferenceProvider);
    final defaultCity =
        (prefCity != null && prefCity.isNotEmpty) ? prefCity : null;

    bool cancelled = false;
    ref.onDispose(() => cancelled = true);
    Future.microtask(() {
      if (!cancelled) _loadFirst();
    });

    return RealtorsState(isLoading: true, cityFilter: defaultCity);
  }

  Future<void> _loadFirst() async {
    _lastDoc = null;
    state = state.copyWith(isLoading: true, realtors: [], hasMore: true);
    await _fetch(paginating: false);
  }

  Future<void> _fetch({required bool paginating}) async {
    final fs = ref.read(firebaseFirestoreProvider);
    final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';

    // Build all where() clauses before orderBy() so Firestore can use the
    // composite index [isProfileComplete, city?, listingsCount DESC].
    Query<Map<String, dynamic>> q = fs
        .collection('users')
        .where('isProfileComplete', isEqualTo: true);

    if (state.cityFilter != null) {
      q = q.where('city', isEqualTo: state.cityFilter);
    }

    q = q.orderBy('listingsCount', descending: true).limit(_pageSize);

    if (paginating && _lastDoc != null) {
      q = q.startAfterDocument(_lastDoc!);
    }

    try {
      final snap = await q.get();
      if (snap.docs.isNotEmpty) _lastDoc = snap.docs.last;

      final users = snap.docs
          .map((d) => UserModel.fromFirestore(d))
          .where((u) => u.uid != myUid)
          .cast<AppUser>()
          .toList();

      if (paginating) {
        state = state.copyWith(
          isLoadingMore: false,
          realtors: [...state.realtors, ...users],
          hasMore: snap.docs.length >= _pageSize,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          realtors: users,
          hasMore: snap.docs.length >= _pageSize,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    await _fetch(paginating: true);
  }

  Future<void> refresh() => _loadFirst();

  void setSearchQuery(String q) {
    if (q == state.searchQuery) return;
    state = state.copyWith(searchQuery: q);
  }

  void applyFilters({
    String? city,
    bool clearCity = false,
    String? accountType,
    bool clearAccountType = false,
    String? category,
    bool clearCategory = false,
  }) {
    final newCity = clearCity ? null : (city ?? state.cityFilter);
    final newType =
        clearAccountType ? null : (accountType ?? state.accountTypeFilter);
    final newCat =
        clearCategory ? null : (category ?? state.categoryFilter);
    if (newCity == state.cityFilter &&
        newType == state.accountTypeFilter &&
        newCat == state.categoryFilter) {
      return;
    }
    state = RealtorsState(
      isLoading: true,
      searchQuery: state.searchQuery,
      cityFilter: newCity,
      accountTypeFilter: newType,
      categoryFilter: newCat,
    );
    Future.microtask(_loadFirst);
  }
}

// ── Single realtor profile provider ──────────────────────────────────────────

@riverpod
Future<AppUser?> realtorProfile(Ref ref, String uid) async {
  final fs = ref.read(firebaseFirestoreProvider);
  final doc = await fs.collection('users').doc(uid).get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
}
