// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$crmRemoteDataSourceHash() => r'placeholder_run_build_runner';
String _$crmRepositoryHash() => r'placeholder_run_build_runner';
String _$crmHash() => r'placeholder_run_build_runner';

@ProviderFor(crmRemoteDataSource)
final crmRemoteDataSourceProvider =
    AutoDisposeProvider<CrmRemoteDataSource>.internal(
  crmRemoteDataSource,
  name: r'crmRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$crmRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef CrmRemoteDataSourceRef = AutoDisposeProviderRef<CrmRemoteDataSource>;

@ProviderFor(crmRepository)
final crmRepositoryProvider = AutoDisposeProvider<CrmRepository>.internal(
  crmRepository,
  name: r'crmRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$crmRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef CrmRepositoryRef = AutoDisposeProviderRef<CrmRepository>;

@ProviderFor(Crm)
final crmProvider = AutoDisposeNotifierProvider<Crm, CrmState>.internal(
  Crm.new,
  name: r'crmProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$crmHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$Crm = AutoDisposeNotifier<CrmState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
