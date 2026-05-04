import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:cpapp/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:cpapp/features/auth/data/models/user_model.dart';

/// Bridges domain [AuthRepository] contract with [AuthRemoteDataSource].
/// Catches all data-layer exceptions and maps them to typed [Failure]s.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final AuthRemoteDataSource _dataSource;

  // ── Auth state ────────────────────────────────────────────────────────────

  @override
  Stream<AppUser?> get authStateChanges {
    return _dataSource.authStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        var profile = await _dataSource.fetchUserProfile(firebaseUser.uid);
        // Retry once — handles the race where profile write is still in-flight
        if (profile == null) {
          await Future.delayed(const Duration(milliseconds: 800));
          profile = await _dataSource.fetchUserProfile(firebaseUser.uid);
        }
        if (profile != null) return profile;
      } catch (_) {
        // Firestore unavailable (permissions, offline) — use Firebase-only data
      }
      return AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
    });
  }

  @override
  AppUser? get currentUser {
    final firebaseUser = _dataSource.currentFirebaseUser;
    if (firebaseUser == null) return null;
    // Lightweight placeholder — full profile fetched asynchronously via stream
    return AppUser(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  // ── Google ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    return _execute(() => _dataSource.signInWithGoogle());
  }

  // ── Facebook ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> signInWithFacebook() async {
    return _execute(() => _dataSource.signInWithFacebook());
  }

  // ── Anonymous ─────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> signInAnonymously() async {
    return _execute(() => _dataSource.signInAnonymously());
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(unit);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, AppUser>> fetchUserProfile(String uid) async {
    try {
      final user = await _dataSource.fetchUserProfile(uid);
      if (user == null) return const Left(NotFoundFailure('User profile not found.'));
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveUserProfile(AppUser user) async {
    try {
      await _dataSource.saveUserProfile(UserModel.fromEntity(user));
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── Generic executor ──────────────────────────────────────────────────────

  Future<Either<Failure, AppUser>> _execute(
    Future<UserModel> Function() call,
  ) async {
    try {
      final user = await call();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.message ?? 'Auth error.'));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
