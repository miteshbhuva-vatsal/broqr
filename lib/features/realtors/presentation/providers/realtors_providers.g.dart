// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtors_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$realtorsHash() => r'placeholder_run_build_runner';
String _$realtorProfileHash() => r'placeholder_run_build_runner';

@ProviderFor(Realtors)
final realtorsProvider =
    AutoDisposeNotifierProvider<Realtors, RealtorsState>.internal(
  Realtors.new,
  name: r'realtorsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$realtorsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$Realtors = AutoDisposeNotifier<RealtorsState>;

@ProviderFor(realtorProfile)
const realtorProfileProvider = RealtorProfileFamily();

final class RealtorProfileFamily
    extends Family<AsyncValue<AppUser?>> {
  const RealtorProfileFamily();

  RealtorProfileProvider call(String uid) =>
      RealtorProfileProvider(uid);

  @override
  RealtorProfileProvider getProviderOverride(
    covariant RealtorProfileProvider provider,
  ) =>
      call(provider.uid);

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'realtorProfileProvider';
}

final class RealtorProfileProvider
    extends AutoDisposeFutureProvider<AppUser?> {
  RealtorProfileProvider(String uid)
      : this._internal(
          (ref) => realtorProfile(ref, uid),
          from: realtorProfileProvider,
          name: r'realtorProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$realtorProfileHash,
          dependencies: RealtorProfileFamily._dependencies,
          allTransitiveDependencies:
              RealtorProfileFamily._allTransitiveDependencies,
          uid: uid,
        );

  RealtorProfileProvider._internal(
    super.create, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
  }) : super.internal();

  final String uid;

  @override
  Override overrideWith(
    FutureOr<AppUser?> Function(AutoDisposeFutureProviderRef<AppUser?> ref)
        create,
  ) =>
      ProviderOverride(
        origin: this,
        override: RealtorProfileProvider._internal(
          (ref) => create(ref as AutoDisposeFutureProviderRef<AppUser?>),
          from: from,
          name: null,
          dependencies: null,
          allTransitiveDependencies: null,
          debugGetCreateSourceHash: null,
          uid: uid,
        ),
      );

  @override
  (String,) get argument => (uid,);

  @override
  AutoDisposeFutureProviderElement<AppUser?> createElement() =>
      _RealtorProfileProviderElement(this);

  @override
  bool operator ==(Object other) {
    return other is RealtorProfileProvider && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

class _RealtorProfileProviderElement
    extends AutoDisposeFutureProviderElement<AppUser?> {
  _RealtorProfileProviderElement(super.provider);

  String get uid => (provider as RealtorProfileProvider).uid;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
