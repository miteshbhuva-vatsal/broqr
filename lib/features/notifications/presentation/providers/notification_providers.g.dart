// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationRemoteDataSourceHash() => r'placeholder_run_build_runner';
String _$notificationRepositoryHash() => r'placeholder_run_build_runner';
String _$notificationsHash() => r'placeholder_run_build_runner';

@ProviderFor(notificationRemoteDataSource)
final notificationRemoteDataSourceProvider =
    AutoDisposeProvider<NotificationRemoteDataSource>.internal(
  notificationRemoteDataSource,
  name: r'notificationRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef NotificationRemoteDataSourceRef =
    AutoDisposeProviderRef<NotificationRemoteDataSource>;

@ProviderFor(notificationRepository)
final notificationRepositoryProvider =
    AutoDisposeProvider<NotificationRepository>.internal(
  notificationRepository,
  name: r'notificationRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef NotificationRepositoryRef =
    AutoDisposeProviderRef<NotificationRepository>;

@ProviderFor(Notifications)
final notificationsProvider =
    AutoDisposeNotifierProvider<Notifications, NotificationState>.internal(
  Notifications.new,
  name: r'notificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$notificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$Notifications = AutoDisposeNotifier<NotificationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
