import 'package:dartz/dartz.dart';

import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/domain/repositories/auth_repository.dart';

/// Sealed state for the auth flow — consumed by the [Auth] Riverpod notifier.
sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated(AppUser user) = AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.error(String message) = AuthStateError;
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated(this.user);
  final AppUser user;
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  const AuthStateError(this.message);
  final String message;
}

/// Thin orchestration layer — calls repository methods and returns [Either].
/// The Riverpod notifier handles state transitions; this handles side effects.
class AuthNotifier {
  const AuthNotifier({required AuthRepository repository})
      : _repository = repository;

  final AuthRepository _repository;

  Future<Either<Failure, AppUser>> signInWithGoogle() =>
      _repository.signInWithGoogle();

  Future<Either<Failure, AppUser>> signInWithFacebook() =>
      _repository.signInWithFacebook();

  Future<Either<Failure, AppUser>> signInAnonymously() =>
      _repository.signInAnonymously();

  Future<Either<Failure, Unit>> signOut() => _repository.signOut();
}
