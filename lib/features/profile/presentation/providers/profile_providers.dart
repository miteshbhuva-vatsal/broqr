import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/providers/city_preference_provider.dart';
import 'package:cpapp/core/providers/navigation_overrides.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:cpapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:cpapp/features/profile/domain/repositories/profile_repository.dart';

part 'profile_providers.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────────

@riverpod
FirebaseStorage firebaseStorage(Ref ref) => FirebaseStorage.instance;

@riverpod
ProfileRemoteDataSource profileRemoteDataSource(Ref ref) {
  return ProfileRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
}

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(
    dataSource: ref.watch(profileRemoteDataSourceProvider),
  );
}

// ── Profile setup state ───────────────────────────────────────────────────

sealed class ProfileSetupState {
  const ProfileSetupState();
  const factory ProfileSetupState.idle() = ProfileSetupIdle;
  const factory ProfileSetupState.saving() = ProfileSetupSaving;
  const factory ProfileSetupState.success() = ProfileSetupSuccess;
  const factory ProfileSetupState.error(String message) = ProfileSetupError;
}

class ProfileSetupIdle extends ProfileSetupState {
  const ProfileSetupIdle();
}

class ProfileSetupSaving extends ProfileSetupState {
  const ProfileSetupSaving();
}

class ProfileSetupSuccess extends ProfileSetupState {
  const ProfileSetupSuccess();
}

class ProfileSetupError extends ProfileSetupState {
  const ProfileSetupError(this.message);
  final String message;
}

// ── Profile setup notifier ────────────────────────────────────────────────

@riverpod
class ProfileSetup extends _$ProfileSetup {
  @override
  ProfileSetupState build() => const ProfileSetupState.idle();

  Future<void> saveProfile({
    required String name,
    required String mobile,
    required String city,
    List<String> workingAreas = const [],
    UserRole? role,
    String? reraNumber,
    File? photoFile,
    String accountType = 'individual',
    String? companyName,
    String? address,
    String? gstNo,
    String? userPersona,
    bool hasCompletedOnboarding = false,
  }) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) {
      state = const ProfileSetupState.error('Not signed in.');
      return;
    }

    state = const ProfileSetupState.saving();

    final result = await ref.read(profileRepositoryProvider).completeProfile(
          uid: user.uid,
          name: name,
          mobile: mobile,
          city: city,
          role: role,
          reraNumber: reraNumber?.isEmpty == true ? null : reraNumber,
          photoFile: photoFile,
          accountType: accountType,
          companyName: companyName,
          address: address,
          gstNo: gstNo,
          orgId: null,
          workingAreas: workingAreas,
          userPersona: userPersona,
          hasCompletedOnboarding: hasCompletedOnboarding,
        );

    result.fold(
      (failure) => state = ProfileSetupState.error(failure.message),
      (_) {
        // Persist city as the default feed filter immediately on profile save.
        if (city.isNotEmpty) {
          ref.read(cityPreferenceProvider.notifier).setCity(city);
        }
        ref.invalidate(authStateChangesProvider);
        state = const ProfileSetupState.success();
      },
    );
  }

  /// Marks onboarding as complete without saving any preference data.
  /// Used by SellerOnboardingScreen after the welcome step.
  Future<void> saveOnboardingComplete() async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;
    state = const ProfileSetupState.saving();
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'hasCompletedOnboarding': true});
      ref.read(onboardingCompleteOverrideProvider.notifier).state = true;
      ref.invalidate(authStateChangesProvider);
      state = const ProfileSetupState.success();
    } catch (e) {
      state = ProfileSetupState.error(e.toString());
    }
  }

  /// Saves full CRM setup: plan type, company details, expertise, associations.
  /// Sets hasConfirmedAccountType = true so the CRM intro never shows again.
  Future<void> saveCrmSetup({
    required String planType,
    String? companyName,
    String? address,
    String? reraNumber,
    String? preferredArea,
    List<String> associations = const [],
    List<String> dealTypes = const [],
    List<String> propertyTypes = const [],
    String? orgId,
  }) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;
    state = const ProfileSetupState.saving();
    try {
      final data = <String, dynamic>{
        'planType': planType,
        'accountType': planType == 'team' ? 'organisation' : 'individual',
        'hasConfirmedAccountType': true,
        'memberships': associations,
        'dealCategories': dealTypes,
        'propertyTypes': propertyTypes,
      };
      if (companyName != null && companyName.isNotEmpty) data['companyName'] = companyName;
      if (address != null && address.isNotEmpty) data['address'] = address;
      if (reraNumber != null && reraNumber.isNotEmpty) data['reraNumber'] = reraNumber;
      if (preferredArea != null && preferredArea.isNotEmpty) {
        data['workingAreas'] = [preferredArea];
      }
      if (orgId != null) data['orgId'] = orgId;
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(data);
      ref.invalidate(authStateChangesProvider);
      state = const ProfileSetupState.success();
    } catch (e) {
      state = ProfileSetupState.error(e.toString());
    }
  }

  /// Lightweight update: saves just accountType (+ optional org fields)
  /// after the user sets their account type from the CRM prompt.
  /// Also marks hasConfirmedAccountType = true so the prompt never shows again.
  Future<void> saveAccountType({
    required String accountType,
    UserRole? role,
    String? orgId,
    String? companyName,
  }) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;
    state = const ProfileSetupState.saving();
    try {
      final data = <String, dynamic>{
        'accountType': accountType,
        'hasConfirmedAccountType': true,
      };
      if (role != null) data['role'] = role.name;
      if (orgId != null) data['orgId'] = orgId;
      if (companyName != null) data['companyName'] = companyName;
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(data);
      ref.invalidate(authStateChangesProvider);
      state = const ProfileSetupState.success();
    } catch (e) {
      state = ProfileSetupState.error(e.toString());
    }
  }

  /// Saves the user's persona (buyer/seller) and sub-type immediately after
  /// they pick on the PersonaSelectionScreen — before profile setup completes.
  /// Uses explicit [uid] to avoid stream timing issues right after sign-in.
  Future<void> savePersona({
    required String persona,
    required String subType,
    required String uid,
  }) async {
    state = const ProfileSetupState.saving();
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set({
        'userPersona': persona,
        'userSubType': subType,
      }, SetOptions(merge: true),);
      ref.invalidate(authStateChangesProvider);
      state = const ProfileSetupState.success();
    } catch (e) {
      state = ProfileSetupState.error(e.toString());
    }
  }

  /// Saves buyer's property & deal type preferences and marks onboarding done.
  Future<void> saveBuyerPreferences({
    required List<String> propertyTypes,
    required List<String> dealTypes,
  }) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;
    state = const ProfileSetupState.saving();
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'preferredPropertyTypes': propertyTypes,
        'preferredDealTypes': dealTypes,
        'hasCompletedOnboarding': true,
      });
      ref.read(onboardingCompleteOverrideProvider.notifier).state = true;
      ref.invalidate(authStateChangesProvider);
      state = const ProfileSetupState.success();
    } catch (e) {
      state = ProfileSetupState.error(e.toString());
    }
  }

  /// Marks hasSetupTeam = true once the team-plan seller finishes org setup.
  Future<void> saveTeamSetupDone() async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;
    state = const ProfileSetupState.saving();
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({'hasSetupTeam': true});
      ref.invalidate(authStateChangesProvider);
      state = const ProfileSetupState.success();
    } catch (e) {
      state = ProfileSetupState.error(e.toString());
    }
  }

  /// Saves the user's professional role (I AM A) selected at login.
  /// Takes an explicit [uid] to avoid stream-timing issues right after sign-in.
  Future<void> saveRole({required UserRole role, required String uid}) async {
    state = const ProfileSetupState.saving();
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set({'role': role.name}, SetOptions(merge: true));
      ref.invalidate(authStateChangesProvider);
      state = const ProfileSetupState.success();
    } catch (e) {
      state = ProfileSetupState.error(e.toString());
    }
  }

  Future<void> updateProfile({
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
  }) async {
    state = const ProfileSetupState.saving();

    final result = await ref.read(profileRepositoryProvider).updateProfile(
          uid: uid,
          name: name,
          mobile: mobile,
          city: city,
          role: role,
          reraNumber: reraNumber?.isEmpty == true ? null : reraNumber,
          photoFile: photoFile,
          dealCategories: dealCategories,
          propertyTypes: propertyTypes,
          workingAreas: workingAreas,
          memberships: memberships,
          isProfilePublic: isProfilePublic,
          userSubType: userSubType,
          preferredDealTypes: preferredDealTypes,
          preferredPropertyTypes: preferredPropertyTypes,
        );

    result.fold(
      (failure) => state = ProfileSetupState.error(failure.message),
      (_) {
        ref.invalidate(authStateChangesProvider);
        state = const ProfileSetupState.success();
      },
    );
  }

  Future<void> submitVerificationRequest({
    required String uid,
    required String name,
    String? reraNumber,
    String? mobile,
  }) async {
    state = const ProfileSetupState.saving();

    final result = await ref
        .read(profileRepositoryProvider)
        .submitVerificationRequest(
          uid: uid,
          name: name,
          reraNumber: reraNumber,
          mobile: mobile,
        );

    result.fold(
      (failure) => state = ProfileSetupState.error(failure.message),
      (_) => state = const ProfileSetupState.success(),
    );
  }

  void clearError() {
    if (state is ProfileSetupError) state = const ProfileSetupState.idle();
  }
}
