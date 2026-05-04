import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';
import 'package:cpapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:cpapp/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({required ProfileRemoteDataSource dataSource})
      : _ds = dataSource;

  final ProfileRemoteDataSource _ds;

  @override
  Future<Either<Failure, AppUser>> completeProfile({
    required String uid,
    required String name,
    required String mobile,
    required String city,
    required UserRole role,
    String? reraNumber,
    File? photoFile,
  }) async {
    try {
      // Upload photo first if provided, get the download URL
      String? photoUrl;
      if (photoFile != null) {
        photoUrl = await _ds.uploadProfilePhoto(uid: uid, file: photoFile);
      }

      final user = await _ds.completeProfile(
        uid: uid,
        name: name,
        mobile: mobile,
        city: city,
        role: role,
        reraNumber: reraNumber,
        photoUrl: photoUrl,
      );
      return Right(user);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    try {
      final url = await _ds.uploadProfilePhoto(uid: uid, file: file);
      return Right(url);
    } on StorageException catch (e) {
      return Left(StorageFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AppUser>> fetchProfile(String uid) async {
    try {
      final user = await _ds.fetchProfile(uid);
      return Right(user);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
