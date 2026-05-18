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
    UserRole? role,
    String? reraNumber,
    File? photoFile,
    String accountType = 'individual',
    String? companyName,
    String? address,
    String? gstNo,
    String? orgId,
    List<String> workingAreas = const [],
    String? userPersona,
    bool hasCompletedOnboarding = false,
  });

  /// Updates an already-complete profile (role is optional).
  Future<Either<Failure, AppUser>> updateProfile({
    required String uid,
    required String name,
    required String mobile,
    required String city,
    UserRole? role,
    String? reraNumber,
    File? photoFile,
    List<String> dealCategories = const [],
    List<String> propertyTypes = const [],
    List<String> workingAreas = const [],
    List<String> memberships = const [],
    bool isProfilePublic = true,
    String? userSubType,
    List<String> preferredDealTypes = const [],
    List<String> preferredPropertyTypes = const [],
  });

  /// Uploads a new profile photo and returns the download URL.
  Future<Either<Failure, String>> uploadProfilePhoto({
    required String uid,
    required File file,
  });

  /// Fetches the current broker profile from Firestore.
  Future<Either<Failure, AppUser>> fetchProfile(String uid);

  /// Submits a verification badge request for admin review.
  Future<Either<Failure, void>> submitVerificationRequest({
    required String uid,
    required String name,
    String? reraNumber,
    String? mobile,
  });
}
