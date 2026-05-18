import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';
import 'package:cpapp/features/listing/data/datasources/listing_remote_datasource.dart';
import 'package:cpapp/features/listing/data/models/listing_model.dart';
import 'package:cpapp/features/listing/data/repositories/listing_repository_impl.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/listing/domain/repositories/listing_repository.dart';
import 'package:cpapp/features/profile/presentation/providers/profile_providers.dart';

part 'listing_providers.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

@riverpod
ListingRemoteDataSource listingRemoteDataSource(Ref ref) {
  return ListingRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
}

@riverpod
ListingRepository listingRepository(Ref ref) {
  return ListingRepositoryImpl(
    dataSource: ref.watch(listingRemoteDataSourceProvider),
  );
}

// ── Add Listing state ─────────────────────────────────────────────────────

/// Holds all form data across the 3 steps of Add Listing.
class AddListingFormState {
  const AddListingFormState({
    this.step = 0,
    this.editingListingId,
    this.category,
    this.propertyType,
    this.title = '',
    this.city = '',
    this.location = '',
    this.area = '',
    this.areaUnit = AreaUnit.sqFt,
    this.price = '',
    this.originalPrice = '',
    this.brokerage = '',
    this.instagramUrl = '',
    this.description = '',
    this.visibility = ListingVisibility.all,
    this.pdfFile,
    this.existingPdfUrl,
    this.heroImage,
    this.existingHeroImageUrl,
    this.additionalImages = const [],
    this.existingAdditionalImageUrls = const [],
    this.isSubmitting = false,
    this.uploadProgress,
    this.errorMessage,
    this.publishedListing,
  });

  final int step;
  final String? editingListingId;
  final ListingCategory? category;
  final PropertyType? propertyType;
  final String title;
  final String city;
  final String location;
  final String area;
  final AreaUnit areaUnit;
  final String price;
  final String originalPrice;
  final String brokerage;
  final String instagramUrl;
  final String description;
  final ListingVisibility visibility;
  final File? pdfFile;
  final String? existingPdfUrl;
  final File? heroImage;
  final String? existingHeroImageUrl;
  final List<File> additionalImages;
  final List<String> existingAdditionalImageUrls;
  final bool isSubmitting;
  final double? uploadProgress;
  final String? errorMessage;
  final Listing? publishedListing;

  bool get isEditMode => editingListingId != null;

  bool get isStep1Valid => category != null;
  bool get isStep2Valid =>
      city.trim().isNotEmpty &&
      location.trim().isNotEmpty &&
      area.trim().isNotEmpty &&
      price.trim().isNotEmpty;
  bool get isStep3Valid =>
      heroImage != null || existingHeroImageUrl != null;

  AddListingFormState copyWith({
    int? step,
    String? editingListingId,
    ListingCategory? category,
    PropertyType? propertyType,
    bool clearPropertyType = false,
    String? title,
    String? city,
    String? location,
    String? area,
    AreaUnit? areaUnit,
    String? price,
    String? originalPrice,
    String? brokerage,
    String? instagramUrl,
    String? description,
    ListingVisibility? visibility,
    File? pdfFile,
    bool clearPdfFile = false,
    String? existingPdfUrl,
    bool clearExistingPdfUrl = false,
    File? heroImage,
    String? existingHeroImageUrl,
    List<File>? additionalImages,
    List<String>? existingAdditionalImageUrls,
    bool? isSubmitting,
    double? uploadProgress,
    String? errorMessage,
    Listing? publishedListing,
    bool clearError = false,
    bool clearListing = false,
    bool clearProgress = false,
  }) {
    return AddListingFormState(
      step: step ?? this.step,
      editingListingId: editingListingId ?? this.editingListingId,
      category: category ?? this.category,
      propertyType: clearPropertyType ? null : (propertyType ?? this.propertyType),
      title: title ?? this.title,
      city: city ?? this.city,
      location: location ?? this.location,
      area: area ?? this.area,
      areaUnit: areaUnit ?? this.areaUnit,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      brokerage: brokerage ?? this.brokerage,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      pdfFile: clearPdfFile ? null : (pdfFile ?? this.pdfFile),
      existingPdfUrl: clearExistingPdfUrl ? null : (existingPdfUrl ?? this.existingPdfUrl),
      heroImage: heroImage ?? this.heroImage,
      existingHeroImageUrl: existingHeroImageUrl ?? this.existingHeroImageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      existingAdditionalImageUrls:
          existingAdditionalImageUrls ?? this.existingAdditionalImageUrls,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadProgress: clearProgress ? null : (uploadProgress ?? this.uploadProgress),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      publishedListing:
          clearListing ? null : (publishedListing ?? this.publishedListing),
    );
  }
}

@riverpod
class AddListing extends _$AddListing {
  @override
  AddListingFormState build() => const AddListingFormState();

  // ── Step navigation ────────────────────────────────────────────────────

  void nextStep() {
    if (state.step < 2) state = state.copyWith(step: state.step + 1);
  }

  void prevStep() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  void goToStep(int step) => state = state.copyWith(step: step);

  // ── Step 1 ─────────────────────────────────────────────────────────────

  void selectCategory(ListingCategory cat) =>
      state = state.copyWith(category: cat, clearPropertyType: true);

  void selectPropertyType(PropertyType? pt) =>
      state = state.copyWith(propertyType: pt, clearPropertyType: pt == null);

  // ── Step 2 ─────────────────────────────────────────────────────────────

  void updateTitle(String v) => state = state.copyWith(title: v);
  void updateCity(String v) => state = state.copyWith(city: v);
  void updateLocation(String v) => state = state.copyWith(location: v);
  void updateArea(String v) => state = state.copyWith(area: v);
  void updateAreaUnit(AreaUnit u) => state = state.copyWith(areaUnit: u);
  void updatePrice(String v) => state = state.copyWith(price: v);
  void updateOriginalPrice(String v) => state = state.copyWith(originalPrice: v);
  void updateBrokerage(String v) => state = state.copyWith(brokerage: v);
  void updateInstagramUrl(String v) => state = state.copyWith(instagramUrl: v);
  void updateDescription(String v) => state = state.copyWith(description: v);
  void setPdfFile(File f) => state = state.copyWith(pdfFile: f);
  void clearPdfFile() => state = state.copyWith(clearPdfFile: true, clearExistingPdfUrl: true);

  // ── Edit mode ──────────────────────────────────────────────────────────────

  void loadForEdit(Listing listing) {
    state = AddListingFormState(
      editingListingId: listing.id,
      step: 0,
      category: listing.category,
      propertyType: listing.propertyType,
      title: listing.title ?? '',
      city: listing.city,
      location: listing.location,
      area: listing.area > 0 ? listing.area.toStringAsFixed(0) : '',
      areaUnit: listing.areaUnit,
      price: listing.price > 0 ? listing.price.toStringAsFixed(0) : '',
      originalPrice: listing.originalPrice != null
          ? listing.originalPrice!.toStringAsFixed(0)
          : '',
      brokerage: listing.brokerageAmount ?? '',
      instagramUrl: listing.instagramUrl ?? '',
      description: listing.description ?? '',
      visibility: listing.visibility,
      existingHeroImageUrl: listing.heroImageUrl,
      existingAdditionalImageUrls: listing.additionalImageUrls,
      existingPdfUrl: listing.pdfUrl,
    );
  }

  void removeExistingAdditionalImage(String url) {
    state = state.copyWith(
      existingAdditionalImageUrls: state.existingAdditionalImageUrls
          .where((u) => u != url)
          .toList(),
    );
  }
  void updateVisibility(ListingVisibility v) => state = state.copyWith(visibility: v);

  // ── Step 3 ─────────────────────────────────────────────────────────────

  void setHeroImage(File f) => state = state.copyWith(heroImage: f);

  void addAdditionalImages(List<File> files) {
    final remaining = 9 - state.additionalImages.length;
    if (remaining <= 0) return;
    final toAdd = files.take(remaining).toList();
    state = state.copyWith(
      additionalImages: [...state.additionalImages, ...toAdd],
    );
  }

  void removeAdditionalImage(int index) {
    final updated = [...state.additionalImages]..removeAt(index);
    state = state.copyWith(additionalImages: updated);
  }

  // ── Publish / Update ──────────────────────────────────────────────────────

  Future<void> publish({List<int>? posterPngBytes}) async {
    if (state.isEditMode) {
      await _updateExisting();
    } else {
      await _createNew(posterPngBytes: posterPngBytes);
    }
  }

  Future<void> _createNew({List<int>? posterPngBytes}) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null || state.heroImage == null || state.category == null) {
      state = state.copyWith(errorMessage: 'Missing required fields.');
      return;
    }

    state = state.copyWith(isSubmitting: true, uploadProgress: 0.0, clearError: true);
    final role = ref.read(authStateChangesProvider).valueOrNull?.role;

    final result = await ref.read(listingRepositoryProvider).createListing(
          brokerUid: user.uid,
          brokerName: user.name,
          brokerPhotoUrl: user.photoUrl,
          brokerPhone: user.mobile,
          title: state.title.trim().isEmpty ? null : state.title.trim(),
          propertyType: state.propertyType,
          category: state.category!,
          city: state.city.trim(),
          location: state.location.trim(),
          area: double.tryParse(state.area) ?? 0,
          areaUnit: state.areaUnit,
          price: double.tryParse(state.price.replaceAll(',', '')) ?? 0,
          originalPrice: state.originalPrice.trim().isEmpty
              ? null
              : double.tryParse(state.originalPrice.replaceAll(',', '')),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          heroImageFile: state.heroImage!,
          additionalImageFiles: state.additionalImages,
          brokerageAmount: state.brokerage.trim().isEmpty
              ? null
              : state.brokerage.trim(),
          instagramUrl: state.instagramUrl.trim().isEmpty
              ? null
              : state.instagramUrl.trim(),
          pdfFile: state.pdfFile,
          posterRole: role?.name,
          visibility: state.visibility,
          onProgress: (p) => state = state.copyWith(uploadProgress: p),
        );

    await result.fold(
      (failure) async {
        state = state.copyWith(
            isSubmitting: false, clearProgress: true, errorMessage: failure.message,);
      },
      (listing) async {
        if (posterPngBytes != null && posterPngBytes.isNotEmpty) {
          await ref.read(listingRepositoryProvider).uploadPoster(
                listingId: listing.id,
                pngBytes: posterPngBytes,
              );
        }
        state = state.copyWith(
            isSubmitting: false, clearProgress: true, publishedListing: listing,);
        unawaited(_notifyFollowers(user, listing));
      },
    );
  }

  Future<void> _updateExisting() async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null || state.editingListingId == null || state.category == null) {
      state = state.copyWith(errorMessage: 'Missing required fields.');
      return;
    }

    state = state.copyWith(isSubmitting: true, uploadProgress: 0.0, clearError: true);

    final result = await ref.read(listingRepositoryProvider).updateListingFull(
          listingId: state.editingListingId!,
          category: state.category!,
          city: state.city.trim(),
          location: state.location.trim(),
          area: double.tryParse(state.area) ?? 0,
          areaUnit: state.areaUnit,
          price: double.tryParse(state.price.replaceAll(',', '')) ?? 0,
          originalPrice: state.originalPrice.trim().isEmpty
              ? null
              : double.tryParse(state.originalPrice.replaceAll(',', '')),
          title: state.title.trim().isEmpty ? null : state.title.trim(),
          propertyType: state.propertyType,
          brokerageAmount: state.brokerage.trim().isEmpty
              ? null
              : state.brokerage.trim(),
          instagramUrl: state.instagramUrl.trim().isEmpty
              ? null
              : state.instagramUrl.trim(),
          description: state.description.trim().isEmpty
              ? null
              : state.description.trim(),
          visibility: state.visibility,
          newHeroImageFile: state.heroImage,
          newAdditionalImageFiles: state.additionalImages,
          keptAdditionalImageUrls: state.existingAdditionalImageUrls,
          newPdfFile: state.pdfFile,
          existingPdfUrl: state.existingPdfUrl,
          onProgress: (p) => state = state.copyWith(uploadProgress: p),
        );

    result.fold(
      (failure) {
        state = state.copyWith(
            isSubmitting: false, clearProgress: true, errorMessage: failure.message,);
      },
      (_) {
        // Synthesise a stub Listing to signal success — detail will reload from Firestore.
        final stub = Listing(
          id: state.editingListingId!,
          brokerUid: user.uid,
          brokerName: user.name,
          category: state.category!,
          city: state.city.trim(),
          location: state.location.trim(),
          area: double.tryParse(state.area) ?? 0,
          price: double.tryParse(state.price.replaceAll(',', '')) ?? 0,
          heroImageUrl: state.existingHeroImageUrl ?? '',
          status: ListingStatus.active,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(
            isSubmitting: false, clearProgress: true, publishedListing: stub,);
      },
    );
  }

  Future<void> _notifyFollowers(dynamic user, Listing listing) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.connectionsCollection)
          .where('followingId', isEqualTo: user.uid as String)
          .get();
      if (snap.docs.isEmpty) return;
      final notifDs = ref.read(notificationRemoteDataSourceProvider);
      for (final doc in snap.docs) {
        final followerUid = doc.data()['followerId'] as String?;
        if (followerUid == null) continue;
        unawaited(notifDs.createNotification(
          recipientUid: followerUid,
          type: NotificationType.newListing,
          title: 'New listing by ${user.name as String}',
          body: '${listing.category.label} in ${listing.city} · ${listing.priceLabel}',
          actorUid: user.uid as String,
          targetId: listing.id,
        ),);
      }
    } catch (_) {}
  }

  void reset() => state = const AddListingFormState();
  void clearError() => state = state.copyWith(clearError: true);
}

// ── Fetch single listing by ID (used for deep-link cold-start) ───────────────

final listingByIdProvider =
    FutureProvider.family<Listing?, String>((ref, id) async {
  if (id.isEmpty) return null;
  final db = ref.read(firebaseFirestoreProvider);
  final doc = await db.collection('listings').doc(id).get();
  if (!doc.exists) return null;
  return ListingModel.fromFirestore(doc);
});

// ── Broker listings (any uid, for profile views) ──────────────────────────────

class BrokerListingsState {
  const BrokerListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });
  final List<Listing> listings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  BrokerListingsState copyWith({
    List<Listing>? listings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return BrokerListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Paginated listings for a single broker (profile screens, my-listings, etc.).
/// Declared manually — no build_runner required.
final brokerListingsProvider = NotifierProvider.autoDispose
    .family<BrokerListings, BrokerListingsState, String>(BrokerListings.new);

class BrokerListings
    extends AutoDisposeFamilyNotifier<BrokerListingsState, String> {
  static const _pageSize = 20;

  @override
  BrokerListingsState build(String brokerUid) {
    if (brokerUid.isNotEmpty) Future.microtask(_load);
    return const BrokerListingsState(isLoading: true);
  }

  Future<void> _load() async {
    final brokerUid = arg;
    final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    final result = await ref
        .read(listingRepositoryProvider)
        .fetchBrokerListings(brokerUid, limit: _pageSize);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (list) {
        final filtered = myUid == brokerUid
            ? list
            : list.where((l) => l.visibility != ListingVisibility.onlyMe).toList();
        state = state.copyWith(
          isLoading: false,
          listings: filtered,
          hasMore: list.length >= _pageSize,
          clearError: true,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.listings.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    final brokerUid = arg;
    final last = state.listings.last;
    final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    final result = await ref.read(listingRepositoryProvider).fetchBrokerListings(
          brokerUid,
          lastCreatedAt: last.createdAt,
          lastDocId: last.id,
          limit: _pageSize,
        );
    result.fold(
      (f) => state = state.copyWith(isLoadingMore: false, error: f.message),
      (more) {
        final filtered = myUid == brokerUid
            ? more
            : more.where((l) => l.visibility != ListingVisibility.onlyMe).toList();
        state = state.copyWith(
          isLoadingMore: false,
          listings: [...state.listings, ...filtered],
          hasMore: more.length >= _pageSize,
          clearError: true,
        );
      },
    );
  }

  Future<void> refresh() async {
    state = const BrokerListingsState(isLoading: true);
    await _load();
  }
}

// ── Org info (name + admin UID) from organisations collection ─────────────────

final orgInfoProvider = FutureProvider.family<
    ({String orgName, String adminUid})?, String>((ref, orgId) async {
  if (orgId.isEmpty) return null;
  final db = ref.read(firebaseFirestoreProvider);
  final doc = await db
      .collection(AppConstants.organisationsCollection)
      .doc(orgId)
      .get();
  final data = doc.data();
  if (data == null) return null;
  return (
    orgName: (data['orgName'] as String?) ?? '',
    adminUid: (data['adminUid'] as String?) ?? '',
  );
});

// ── Org-combined listings: member's own + admin's listings merged ─────────────

Future<List<Listing>> _fetchFirst20(Ref ref, String brokerUid) async {
  if (brokerUid.isEmpty) return [];
  final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
  final result = await ref
      .read(listingRepositoryProvider)
      .fetchBrokerListings(brokerUid, limit: 20);
  return result.fold((_) => [], (list) {
    if (myUid == brokerUid) return list;
    return list.where((l) => l.visibility != ListingVisibility.onlyMe).toList();
  });
}

final orgCombinedListingsProvider = FutureProvider.family<List<Listing>,
    ({String uid, String? orgId})>((ref, args) async {
  final myListings = await _fetchFirst20(ref, args.uid);
  if (args.orgId == null) return myListings;
  final orgInfo = await ref.read(orgInfoProvider(args.orgId!).future);
  if (orgInfo == null ||
      orgInfo.adminUid.isEmpty ||
      orgInfo.adminUid == args.uid) {
    return myListings;
  }
  final adminListings = await _fetchFirst20(ref, orgInfo.adminUid);
  final seen = <String>{};
  return [...myListings, ...adminListings]
      .where((l) => seen.add(l.id))
      .toList();
});

// ── Inquired listings (buyer profile) ────────────────────────────────────────

final inquiredListingsProvider =
    FutureProvider<List<Listing>>((ref) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
  if (uid.isEmpty) return [];
  final idsResult =
      await ref.read(listingRepositoryProvider).fetchInquiredListingIds(uid);
  final ids = idsResult.fold((_) => <String>[], (list) => list);
  if (ids.isEmpty) return [];
  final db = ref.read(firebaseFirestoreProvider);
  // Fetch in batches of 10 (Firestore whereIn limit).
  final listings = <Listing>[];
  for (var i = 0; i < ids.length; i += 10) {
    final batch = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
    final snap = await db
        .collection(AppConstants.listingsCollection)
        .where(FieldPath.documentId, whereIn: batch)
        .get();
    listings.addAll(snap.docs.map(ListingModel.fromFirestore));
  }
  return listings;
});

// ── My Listings ───────────────────────────────────────────────────────────────

class MyListingsState {
  const MyListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });
  final List<Listing> listings;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  static const _pageSize = 20;

  MyListingsState copyWith({
    List<Listing>? listings,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return MyListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class MyListings extends _$MyListings {
  static const _pageSize = MyListingsState._pageSize;

  @override
  MyListingsState build() {
    Future.microtask(() => _load());
    return const MyListingsState(isLoading: true);
  }

  Future<void> _load() async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final result = await ref
        .read(listingRepositoryProvider)
        .fetchBrokerListings(uid, limit: _pageSize);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (list) => state = state.copyWith(
        isLoading: false,
        listings: list,
        hasMore: list.length >= _pageSize,
        clearError: true,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.listings.isEmpty) return;
    state = state.copyWith(isLoadingMore: true);
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    final last = state.listings.last;
    final result = await ref.read(listingRepositoryProvider).fetchBrokerListings(
          uid,
          lastCreatedAt: last.createdAt,
          lastDocId: last.id,
          limit: _pageSize,
        );
    result.fold(
      (f) => state = state.copyWith(isLoadingMore: false, error: f.message),
      (more) => state = state.copyWith(
        isLoadingMore: false,
        listings: [...state.listings, ...more],
        hasMore: more.length >= _pageSize,
        clearError: true,
      ),
    );
  }

  Future<void> refresh() async {
    state = const MyListingsState(isLoading: true);
    await _load();
  }
}
