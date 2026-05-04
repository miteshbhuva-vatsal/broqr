// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$networkRemoteDataSourceHash() => r'placeholder_run_build_runner';
String _$networkRepositoryHash() => r'placeholder_run_build_runner';
String _$networkHash() => r'placeholder_run_build_runner';

@ProviderFor(networkRemoteDataSource)
final networkRemoteDataSourceProvider =
    AutoDisposeProvider<NetworkRemoteDataSource>.internal(
  networkRemoteDataSource,
  name: r'networkRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef NetworkRemoteDataSourceRef =
    AutoDisposeProviderRef<NetworkRemoteDataSource>;

@ProviderFor(networkRepository)
final networkRepositoryProvider =
    AutoDisposeProvider<NetworkRepository>.internal(
  networkRepository,
  name: r'networkRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef NetworkRepositoryRef = AutoDisposeProviderRef<NetworkRepository>;

@ProviderFor(Network)
final networkProvider =
    AutoDisposeNotifierProvider<Network, NetworkState>.internal(
  Network.new,
  name: r'networkProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$networkHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$Network = AutoDisposeNotifier<NetworkState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
