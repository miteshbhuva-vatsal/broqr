import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';

/// Contract for broker profile read/write operations.
abstract interface class ProfileRepository {
  /// Saves profile fields + marks [isProfileComplete] true.
  Future<Either<Failure, AppUser>> completeProfile({
    required String uid,
    required String name,
    required String mobile,
    required String city,
    required UserRole role,
    String? reraNumber,
    File? photoFile,
  });

  /// Uploads a new profile photo and returns the download URL.
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String uid,
    required File file,
  });

  /// Fetches the current broker profile from Firestore.
  Future<Either<Failure, AppUser>> fetchProfile(String uid);
}
