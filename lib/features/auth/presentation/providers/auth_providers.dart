import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cpapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cpapp/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_notifier.dart';

part 'auth_providers.g.dart';

// ── SDK singletons ────────────────────────────────────────────────────────

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) => FirebaseFirestore.instance;

@riverpod
GoogleSignIn googleSignIn(Ref ref) => GoogleSignIn(scopes: ['email', 'profile']);

@riverpod
FacebookAuth facebookAuth(Ref ref) => FacebookAuth.instance;

// ── Data source ───────────────────────────────────────────────────────────

@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
    googleSignIn: ref.watch(googleSignInProvider),
    facebookAuth: ref.watch(facebookAuthProvider),
  );
}

// ── Repository ────────────────────────────────────────────────────────────

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(authRemoteDataSourceProvider),
  );
}

// ── Auth state stream ─────────────────────────────────────────────────────

/// Emits the current [AppUser] on every auth state change.
/// Used by GoRouter redirect and any widget that needs auth state.
@riverpod
Stream<AppUser?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

// ── Phone verification ────────────────────────────────────────────────────

/// Flipped to true within this session after successful OTP verification.
/// Persists in memory so UI updates instantly without waiting for auth reload.
final sessionPhoneVerifiedProvider = StateProvider<bool>((_) => false);

/// True when the user's phone is verified — either from Firestore or this session.
final isPhoneVerifiedProvider = Provider<bool>((ref) {
  if (ref.watch(sessionPhoneVerifiedProvider)) return true;
  return ref.watch(authStateChangesProvider).valueOrNull?.isPhoneVerified ?? false;
});

// ── Auth notifier (actions) ───────────────────────────────────────────────

@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() => const AuthState.initial();

  AuthNotifier get _notifier =>
      AuthNotifier(repository: ref.read(authRepositoryProvider));

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    final result = await _notifier.signInWithGoogle();
    result.fold(
      (failure) {
        if (_isCancellation(failure.message)) {
          state = const AuthState.unauthenticated();
        } else {
          state = AuthState.error(failure.message);
        }
      },
      (user) => state = AuthState.authenticated(user),
    );
  }

  Future<void> signInWithFacebook() async {
    state = const AuthState.loading();
    final result = await _notifier.signInWithFacebook();
    result.fold(
      (failure) {
        if (_isCancellation(failure.message)) {
          state = const AuthState.unauthenticated();
        } else {
          state = AuthState.error(failure.message);
        }
      },
      (user) => state = AuthState.authenticated(user),
    );
  }

  static bool _isCancellation(String message) =>
      message == 'cancelled' || message.toLowerCase().contains('cancel');

  Future<void> signInAnonymously() async {
    state = const AuthState.loading();
    final result = await _notifier.signInAnonymously();
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (user) => state = AuthState.authenticated(user),
    );
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    final result = await _notifier.signOut();
    result.fold(
      (failure) => state = AuthState.error(failure.message),
      (_) => state = const AuthState.unauthenticated(),
    );
  }

  void clearError() {
    if (state is AuthStateError) state = const AuthState.unauthenticated();
  }
}
