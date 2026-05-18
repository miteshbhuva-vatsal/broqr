import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/auth/data/models/user_model.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';

abstract interface class ProfileRemoteDataSource {
  Future<UserModel> completeProfile({
    required String uid,
    required String name,
    required String mobile,
    required String city,
    UserRole? role,
    String? reraNumber,
    String? photoUrl,
    String accountType = 'individual',
    String? companyName,
    String? address,
    String? gstNo,
    String? orgId,
    List<String> workingAreas = const [],
    String? userPersona,
    bool hasCompletedOnboarding = false,
  });

  Future<UserModel> updateProfile({
    required String uid,
    required String name,
    required String mobile,
    required String city,
    UserRole? role,
    String? reraNumber,
    String? photoUrl,
    List<String> dealCategories = const [],
    List<String> propertyTypes = const [],
    List<String> workingAreas = const [],
    List<String> memberships = const [],
    bool isProfilePublic = true,
    String? userSubType,
    List<String> preferredDealTypes = const [],
    List<String> preferredPropertyTypes = const [],
  });

  Future<String> uploadProfilePhoto({required String uid, required File file});

  Future<UserModel> fetchProfile(String uid);

  Future<void> submitVerificationRequest({
    required String uid,
    required String name,
    String? reraNumber,
    String? mobile,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<UserModel> completeProfile({
    required String uid,
    required String name,
    required String mobile,
    required String city,
    UserRole? role,
    String? reraNumber,
    String? photoUrl,
    String accountType = 'individual',
    String? companyName,
    String? address,
    String? gstNo,
    String? orgId,
    List<String> workingAreas = const [],
    String? userPersona,
    bool hasCompletedOnboarding = false,
  }) async {
    try {
      final updates = <String, dynamic>{
        'uid': uid,
        'name': name.trim(),
        'mobile': mobile.trim(),
        'city': city.trim(),
        'reraNumber': reraNumber?.trim(),
        if (role != null) 'role': role.name,
        'isProfileComplete': true,
        'accountType': accountType,
        'updatedAt': FieldValue.serverTimestamp(),
        if (companyName != null) 'companyName': companyName.trim(),
        if (address != null) 'address': address.trim(),
        if (gstNo != null) 'gstNo': gstNo.trim(),
        if (orgId != null) 'orgId': orgId,
        if (workingAreas.isNotEmpty) 'workingAreas': workingAreas,
        if (userPersona != null) 'userPersona': userPersona,
        if (hasCompletedOnboarding) 'hasCompletedOnboarding': true,
        if (hasCompletedOnboarding) 'hasConfirmedAccountType': true,
        if (hasCompletedOnboarding) 'hasSetupTeam': true,
      };
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      // Use set+merge so the write succeeds even if the doc doesn't exist yet
      // (OTP users have no Firestore doc until completeProfile is called).
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(updates, SetOptions(merge: true));

      return fetchProfile(uid);
    } catch (e) {
      throw ServerException('Failed to save profile: $e');
    }
  }

  @override
  Future<String> uploadProfilePhoto({
    required String uid,
    required File file,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('${AppConstants.profileImagesPath}/$uid/avatar.jpg');

      final task = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw StorageException('Photo upload failed: $e');
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String uid,
    required String name,
    required String mobile,
    required String city,
    UserRole? role,
    String? reraNumber,
    String? photoUrl,
    List<String> dealCategories = const [],
    List<String> propertyTypes = const [],
    List<String> workingAreas = const [],
    List<String> memberships = const [],
    bool isProfilePublic = true,
    String? userSubType,
    List<String> preferredDealTypes = const [],
    List<String> preferredPropertyTypes = const [],
  }) async {
    try {
      final updates = <String, dynamic>{
        'name': name.trim(),
        'mobile': mobile.trim(),
        'city': city.trim(),
        'reraNumber': reraNumber?.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'dealCategories': dealCategories,
        'propertyTypes': propertyTypes,
        'workingAreas': workingAreas,
        'memberships': memberships,
        'isProfilePublic': isProfilePublic,
      };

      if (role != null) updates['role'] = role.name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      if (userSubType != null) updates['userSubType'] = userSubType;
      if (preferredDealTypes.isNotEmpty) updates['preferredDealTypes'] = preferredDealTypes;
      if (preferredPropertyTypes.isNotEmpty) updates['preferredPropertyTypes'] = preferredPropertyTypes;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updates);

      return fetchProfile(uid);
    } catch (e) {
      throw ServerException('Failed to update profile: $e');
    }
  }

  @override
  Future<void> submitVerificationRequest({
    required String uid,
    required String name,
    String? reraNumber,
    String? mobile,
  }) async {
    try {
      await _firestore.collection('verificationRequests').doc(uid).set({
        'uid': uid,
        'name': name,
        'reraNumber': reraNumber,
        'mobile': mobile,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to submit verification request: $e');
    }
  }

  @override
  Future<UserModel> fetchProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) throw const NotFoundException('Profile not found.');
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to fetch profile: $e');
    }
  }
}
