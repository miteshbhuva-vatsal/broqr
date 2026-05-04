// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseAuthHash() => r'placeholder_run_build_runner';
String _$firebaseFirestoreHash() => r'placeholder_run_build_runner';
String _$googleSignInHash() => r'placeholder_run_build_runner';
String _$facebookAuthHash() => r'placeholder_run_build_runner';
String _$authRemoteDataSourceHash() => r'placeholder_run_build_runner';
String _$authRepositoryHash() => r'placeholder_run_build_runner';
String _$authStateChangesHash() => r'placeholder_run_build_runner';
String _$authHash() => r'placeholder_run_build_runner';

@ProviderFor(firebaseAuth)
final firebaseAuthProvider = AutoDisposeProvider<FirebaseAuth>.internal(
  firebaseAuth,
  name: r'firebaseAuthProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firebaseAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef FirebaseAuthRef = AutoDisposeProviderRef<FirebaseAuth>;

@ProviderFor(firebaseFirestore)
final firebaseFirestoreProvider =
    AutoDisposeProvider<FirebaseFirestore>.internal(
  firebaseFirestore,
  name: r'firebaseFirestoreProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseFirestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef FirebaseFirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;

@ProviderFor(googleSignIn)
final googleSignInProvider = AutoDisposeProvider<GoogleSignIn>.internal(
  googleSignIn,
  name: r'googleSignInProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$googleSignInHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef GoogleSignInRef = AutoDisposeProviderRef<GoogleSignIn>;

@ProviderFor(facebookAuth)
final facebookAuthProvider = AutoDisposeProvider<FacebookAuth>.internal(
  facebookAuth,
  name: r'facebookAuthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$facebookAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef FacebookAuthRef = AutoDisposeProviderRef<FacebookAuth>;

@ProviderFor(authRemoteDataSource)
final authRemoteDataSourceProvider =
    AutoDisposeProvider<AuthRemoteDataSource>.internal(
  authRemoteDataSource,
  name: r'authRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef AuthRemoteDataSourceRef = AutoDisposeProviderRef<AuthRemoteDataSource>;

@ProviderFor(authRepository)
final authRepositoryProvider = AutoDisposeProvider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef AuthRepositoryRef = AutoDisposeProviderRef<AuthRepository>;

@ProviderFor(authStateChanges)
final authStateChangesProvider = AutoDisposeStreamProvider<AppUser?>.internal(
  authStateChanges,
  name: r'authStateChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
@Deprecated('Will be removed in 3.0. Use Ref instead')
typedef AuthStateChangesRef = AutoDisposeStreamProviderRef<AppUser?>;

@ProviderFor(Auth)
final authProvider = AutoDisposeNotifierProvider<Auth, AuthState>.internal(
  Auth.new,
  name: r'authProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authHash,
  dependencies: null,
  allTransitiveDependencies: null,
);
typedef _$Auth = AutoDisposeNotifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
