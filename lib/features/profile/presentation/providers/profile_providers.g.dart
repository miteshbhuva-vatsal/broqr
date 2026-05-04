// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseStorageHash() => r'placeholder_run_build_runner';
String _$profileRemoteDataSourceHash() => r'placeholder_run_build_runner';
String _$profileRepositoryHash() => r'placeholder_run_build_runner';
String _$profileSetupHash() => r'placeholder_run_build_runner';

@ProviderFor(firebaseStorage)
final firebaseStorageProvider = AutoDisposeProvider<FirebaseStorage>.internal(
  firebaseStorage,
  name: r'firebaseStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef FirebaseStorageRef = AutoDisposeProviderRef<FirebaseStorage>;

@ProviderFor(profileRemoteDataSource)
final profileRemoteDataSourceProvider =
    AutoDisposeProvider<ProfileRemoteDataSource>.internal(
  profileRemoteDataSource,
  name: r'profileRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef ProfileRemoteDataSourceRef
    = AutoDisposeProviderRef<ProfileRemoteDataSource>;

@ProviderFor(profileRepository)
final profileRepositoryProvider =
    AutoDisposeProvider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef ProfileRepositoryRef = AutoDisposeProviderRef<ProfileRepository>;

@ProviderFor(ProfileSetup)
final profileSetupProvider =
    AutoDisposeNotifierProvider<ProfileSetup, ProfileSetupState>.internal(
  ProfileSetup.new,
  name: r'profileSetupProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileSetupHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$ProfileSetup = AutoDisposeNotifier<ProfileSetupState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
