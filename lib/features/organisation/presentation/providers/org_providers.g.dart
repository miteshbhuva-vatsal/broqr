// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'org_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$orgRemoteDataSourceHash() => r'placeholder_run_build_runner';
String _$orgRepositoryHash() => r'placeholder_run_build_runner';
String _$watchCurrentOrgHash() => r'placeholder_run_build_runner';
String _$watchOrgMembersHash() => r'placeholder_run_build_runner';
String _$watchOrgTeamsHash() => r'placeholder_run_build_runner';
String _$currentOrgMemberHash() => r'placeholder_run_build_runner';
String _$pendingInvitesHash() => r'placeholder_run_build_runner';
String _$allOrgInvitesHash() => r'placeholder_run_build_runner';
String _$callerTeamIdsHash() => r'placeholder_run_build_runner';
String _$orgActionsHash() => r'placeholder_run_build_runner';

@ProviderFor(orgRemoteDataSource)
final orgRemoteDataSourceProvider =
    AutoDisposeProvider<OrganisationRemoteDataSource>.internal(
  orgRemoteDataSource,
  name: r'orgRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orgRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef OrgRemoteDataSourceRef
    = AutoDisposeProviderRef<OrganisationRemoteDataSource>;

@ProviderFor(orgRepository)
final orgRepositoryProvider =
    AutoDisposeProvider<OrganisationRepository>.internal(
  orgRepository,
  name: r'orgRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$orgRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef OrgRepositoryRef = AutoDisposeProviderRef<OrganisationRepository>;

@ProviderFor(watchCurrentOrg)
final watchCurrentOrgProvider =
    AutoDisposeStreamProvider<Organisation>.internal(
  watchCurrentOrg,
  name: r'watchCurrentOrgProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchCurrentOrgHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef WatchCurrentOrgRef = AutoDisposeStreamProviderRef<Organisation>;

@ProviderFor(watchOrgMembers)
final watchOrgMembersProvider =
    AutoDisposeStreamProvider<List<OrgMember>>.internal(
  watchOrgMembers,
  name: r'watchOrgMembersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchOrgMembersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef WatchOrgMembersRef = AutoDisposeStreamProviderRef<List<OrgMember>>;

@ProviderFor(watchOrgTeams)
final watchOrgTeamsProvider = AutoDisposeStreamProvider<List<OrgTeam>>.internal(
  watchOrgTeams,
  name: r'watchOrgTeamsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$watchOrgTeamsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef WatchOrgTeamsRef = AutoDisposeStreamProviderRef<List<OrgTeam>>;

@ProviderFor(currentOrgMember)
final currentOrgMemberProvider = AutoDisposeFutureProvider<OrgMember?>.internal(
  currentOrgMember,
  name: r'currentOrgMemberProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentOrgMemberHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef CurrentOrgMemberRef = AutoDisposeFutureProviderRef<OrgMember?>;

@ProviderFor(pendingInvites)
final pendingInvitesProvider =
    AutoDisposeFutureProvider<List<OrgInvite>>.internal(
  pendingInvites,
  name: r'pendingInvitesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingInvitesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef PendingInvitesRef = AutoDisposeFutureProviderRef<List<OrgInvite>>;

@ProviderFor(allOrgInvites)
final allOrgInvitesProvider =
    AutoDisposeFutureProvider<List<OrgInvite>>.internal(
  allOrgInvites,
  name: r'allOrgInvitesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$allOrgInvitesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef AllOrgInvitesRef = AutoDisposeFutureProviderRef<List<OrgInvite>>;

@ProviderFor(callerTeamIds)
final callerTeamIdsProvider = AutoDisposeFutureProvider<List<String>>.internal(
  callerTeamIds,
  name: r'callerTeamIdsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$callerTeamIdsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef CallerTeamIdsRef = AutoDisposeFutureProviderRef<List<String>>;

@ProviderFor(OrgActions)
final orgActionsProvider =
    AutoDisposeNotifierProvider<OrgActions, AsyncValue<void>>.internal(
  OrgActions.new,
  name: r'orgActionsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$orgActionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$OrgActions = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
