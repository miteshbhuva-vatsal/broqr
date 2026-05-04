// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'listing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$listingRemoteDataSourceHash() => r'placeholder_run_build_runner';
String _$listingRepositoryHash() => r'placeholder_run_build_runner';
String _$addListingHash() => r'placeholder_run_build_runner';
String _$myListingsHash() => r'placeholder_run_build_runner';

@ProviderFor(listingRemoteDataSource)
final listingRemoteDataSourceProvider =
    AutoDisposeProvider<ListingRemoteDataSource>.internal(
  listingRemoteDataSource,
  name: r'listingRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$listingRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef ListingRemoteDataSourceRef
    = AutoDisposeProviderRef<ListingRemoteDataSource>;

@ProviderFor(listingRepository)
final listingRepositoryProvider =
    AutoDisposeProvider<ListingRepository>.internal(
  listingRepository,
  name: r'listingRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$listingRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef ListingRepositoryRef = AutoDisposeProviderRef<ListingRepository>;

@ProviderFor(AddListing)
final addListingProvider =
    AutoDisposeNotifierProvider<AddListing, AddListingFormState>.internal(
  AddListing.new,
  name: r'addListingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$addListingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$AddListing = AutoDisposeNotifier<AddListingFormState>;

@ProviderFor(MyListings)
final myListingsProvider =
    AutoDisposeNotifierProvider<MyListings, MyListingsState>.internal(
  MyListings.new,
  name: r'myListingsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myListingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$MyListings = AutoDisposeNotifier<MyListingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
