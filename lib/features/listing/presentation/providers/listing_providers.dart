import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
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
    this.description = '',
    this.visibility = ListingVisibility.all,
    this.heroImage,
    this.additionalImages = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.publishedListing,
  });

  final int step;
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
  final String description;
  final ListingVisibility visibility;
  final File? heroImage;
  final List<File> additionalImages;
  final bool isSubmitting;
  final String? errorMessage;
  final Listing? publishedListing;

  bool get isStep1Valid => category != null;
  bool get isStep2Valid =>
      city.trim().isNotEmpty &&
      location.trim().isNotEmpty &&
      area.trim().isNotEmpty &&
      price.trim().isNotEmpty;
  bool get isStep3Valid => heroImage != null;

  AddListingFormState copyWith({
    int? step,
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
    String? description,
    ListingVisibility? visibility,
    File? heroImage,
    List<File>? additionalImages,
    bool? isSubmitting,
    String? errorMessage,
    Listing? publishedListing,
    bool clearError = false,
    bool clearListing = false,
  }) {
    return AddListingFormState(
      step: step ?? this.step,
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
      description: description ?? this.description,
      visibility: visibility ?? this.visibility,
      heroImage: heroImage ?? this.heroImage,
      additionalImages: additionalImages ?? this.additionalImages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
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
  void updateDescription(String v) => state = state.copyWith(description: v);
  void updateVisibility(ListingVisibility v) => state = state.copyWith(visibility: v);

  // ── Step 3 ─────────────────────────────────────────────────────────────

  void setHeroImage(File f) => state = state.copyWith(heroImage: f);

  void addAdditionalImage(File f) {
    if (state.additionalImages.length >= 4) return;
    state = state.copyWith(
        additionalImages: [...state.additionalImages, f],);
  }

  void removeAdditionalImage(int index) {
    final updated = [...state.additionalImages]..removeAt(index);
    state = state.copyWith(additionalImages: updated);
  }

  // ── Publish ────────────────────────────────────────────────────────────

  Future<void> publish({List<int>? posterPngBytes}) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null || state.heroImage == null || state.category == null) {
      state = state.copyWith(errorMessage: 'Missing required fields.');
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

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
          posterRole: role?.name,
          visibility: state.visibility,
        );

    await result.fold(
      (failure) async {
        state = state.copyWith(
            isSubmitting: false, errorMessage: failure.message,);
      },
      (listing) async {
        // Upload poster if bytes provided
        if (posterPngBytes != null && posterPngBytes.isNotEmpty) {
          await ref.read(listingRepositoryProvider).uploadPoster(
                listingId: listing.id,
                pngBytes: posterPngBytes,
              );
        }
        state = state.copyWith(
            isSubmitting: false, publishedListing: listing,);
      },
    );
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

final brokerListingsProvider =
    FutureProvider.family<List<Listing>, String>((ref, brokerUid) async {
  if (brokerUid.isEmpty) return [];
  final myUid = ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
  final result =
      await ref.read(listingRepositoryProvider).fetchBrokerListings(brokerUid);
  return result.fold((_) => [], (list) {
    if (myUid == brokerUid) return list; // own profile — show all
    return list
        .where((l) => l.visibility != ListingVisibility.onlyMe)
        .toList();
  });
});

// ── My Listings ───────────────────────────────────────────────────────────────

class MyListingsState {
  const MyListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.error,
  });
  final List<Listing> listings;
  final bool isLoading;
  final String? error;

  MyListingsState copyWith({
    List<Listing>? listings,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MyListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

@riverpod
class MyListings extends _$MyListings {
  @override
  MyListingsState build() {
    Future.microtask(() => _load());
    return const MyListingsState(isLoading: true);
  }

  Future<void> _load() async {
    final uid =
        ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    if (uid.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final result =
        await ref.read(listingRepositoryProvider).fetchBrokerListings(uid);
    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (listings) =>
          state = state.copyWith(isLoading: false, listings: listings),
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load();
  }
}
