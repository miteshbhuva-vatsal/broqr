import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    required UserRole role,
    String? reraNumber,
    File? photoFile,
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
