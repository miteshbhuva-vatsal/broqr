import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/auth/data/models/user_model.dart';

/// Raw Firebase / social SDK calls.
/// All methods throw typed [Exception]s — never [Failure]s.
/// The repository converts these to [Failure]s for the domain layer.
abstract interface class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;
  User? get currentFirebaseUser;

  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithFacebook();
  Future<UserModel> signInAnonymously();
  Future<void> signOut();
  Future<UserModel?> fetchUserProfile(String uid);
  Future<void> saveUserProfile(UserModel model);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
    required FacebookAuth facebookAuth,
  })  : _auth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn,
        _facebookAuth = facebookAuth;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  // ── Auth state stream ────────────────────────────────────────────────────

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentFirebaseUser => _auth.currentUser;

  // ── Google Sign-In ────────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Triggers the Google account picker
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthException('cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      return _resolveUserModel(
        firebaseUser: firebaseUser,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
        displayName: googleUser.displayName ?? firebaseUser.displayName ?? '',
        photoUrl: googleUser.photoUrl ?? firebaseUser.photoURL,
      );
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Google sign-in failed.');
    } on PlatformException catch (e) {
      // sign_in_canceled = user dismissed the picker; sign_in_failed on emulator
      if (e.code == 'sign_in_canceled' || e.code == 'sign_in_failed') {
        throw const AuthException('cancelled');
      }
      throw AuthException(e.message ?? 'Google sign-in failed.');
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  // ── Facebook Login ────────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithFacebook() async {
    try {
      final result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        throw const AuthException('cancelled');
      }
      if (result.status != LoginStatus.success) {
        throw AuthException(result.message ?? 'Facebook login failed.');
      }

      final credential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user!;

      // Fetch full Facebook profile for name + photo
      final fbData = await _facebookAuth.getUserData(
        fields: 'name,email,picture.width(200)',
      );

      final photoUrl = fbData['picture']?['data']?['url'] as String? ??
          firebaseUser.photoURL;

      return _resolveUserModel(
        firebaseUser: firebaseUser,
        isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
        displayName: fbData['name'] as String? ??
            firebaseUser.displayName ??
            '',
        photoUrl: photoUrl,
      );
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Facebook login failed.');
    } catch (e) {
      throw AuthException('Facebook login failed: $e');
    }
  }

  // ── Anonymous sign-in (debug / testing) ──────────────────────────────────

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      final uid = credential.user!.uid;

      // Check if a profile already exists for this anonymous session
      final existing = await fetchUserProfile(uid);
      if (existing != null) return existing;

      // Create a complete test profile so the router skips profile setup
      final testUser = UserModel(
        uid: uid,
        name: 'Test Broker',
        email: 'test@cpapp.dev',
        city: 'Mumbai',
        reraNumber: 'MH/2024/TEST001',
        isProfileComplete: true,
        isVerified: false,
        listingsCount: 0,
        connectionsCount: 0,
        createdAt: DateTime.now(),
      );
      await saveUserProfile(testUser);
      return testUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Anonymous sign-in failed.');
    } catch (e) {
      throw AuthException('Anonymous sign-in failed: $e');
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
      _facebookAuth.logOut(),
    ]);
  }

  // ── Firestore user profile ────────────────────────────────────────────────

  @override
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final doc = await _users
          .doc(uid)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (data, _) => data,
          )
          .get();

      if (!doc.exists || doc.data() == null) return null;

      // Re-fetch as typed snapshot for UserModel
      final typedDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      return UserModel.fromFirestore(typedDoc);
    } catch (e) {
      throw ServerException('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<void> saveUserProfile(UserModel model) async {
    try {
      await _users.doc(model.uid).set(model.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw ServerException('Failed to save user profile: $e');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Returns stored profile for returning users; creates a minimal one for new users.
  Future<UserModel> _resolveUserModel({
    required User firebaseUser,
    required bool isNewUser,
    required String displayName,
    String? photoUrl,
  }) async {
    if (isNewUser) {
      // First login — create minimal Firestore document
      final newUser = UserModel.fromNewSocialLogin(
        uid: firebaseUser.uid,
        name: displayName,
        email: firebaseUser.email ?? '',
        photoUrl: photoUrl,
      );
      await saveUserProfile(newUser);
      return newUser;
    }

    // Returning user — load full profile from Firestore
    final stored = await fetchUserProfile(firebaseUser.uid);
    if (stored != null) return stored;

    // Firestore doc missing (edge case) — recreate it
    final fallback = UserModel.fromNewSocialLogin(
      uid: firebaseUser.uid,
      name: displayName,
      email: firebaseUser.email ?? '',
      photoUrl: photoUrl,
    );
    await saveUserProfile(fallback);
    return fallback;
  }
}
