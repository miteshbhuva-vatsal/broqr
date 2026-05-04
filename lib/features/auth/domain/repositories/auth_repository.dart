import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';

/// Contract for all authentication operations.
/// Implementations live in the data layer — domain never touches Firebase directly.
abstract interface class AuthRepository {
  /// Emits the currently signed-in [AppUser], or null when signed out.
  Stream<AppUser?> get authStateChanges;

  /// Returns the currently cached user, or null.
  AppUser? get currentUser;

  /// Signs in with Google OAuth. Returns the user on success.
  Future<Either<Failure, AppUser>> signInWithGoogle();

  /// Signs in with Facebook OAuth. Returns the user on success.
  Future<Either<Failure, AppUser>> signInWithFacebook();

  /// Signs in anonymously (debug / testing only).
  Future<Either<Failure, AppUser>> signInAnonymously();

  /// Signs out from all providers.
  Future<Either<Failure, Unit>> signOut();

  /// Fetches the full broker profile from Firestore.
  Future<Either<Failure, AppUser>> fetchUserProfile(String uid);

  /// Creates or updates the user document in Firestore.
  Future<Either<Failure, Unit>> saveUserProfile(AppUser user);
}
