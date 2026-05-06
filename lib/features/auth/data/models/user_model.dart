import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';

/// Firestore-serialisable representation of [AppUser].
/// Converts to/from Map for Firestore reads and writes.
class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    required super.createdAt,
    super.photoUrl,
    super.mobile,
    super.city,
    super.reraNumber,
    super.role,
    super.referralCode,
    super.isProfileComplete,
    super.isVerified,
    super.isPhoneVerified,
    super.listingsCount,
    super.connectionsCount,
    super.lastSeen,
  });

  /// Constructs a [UserModel] from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      mobile: data['mobile'] as String?,
      city: data['city'] as String?,
      reraNumber: data['reraNumber'] as String?,
      role: UserRole.fromString(data['role'] as String?),
      referralCode: data['referralCode'] as String?,
      isProfileComplete: data['isProfileComplete'] as bool? ?? false,
      isVerified: data['isVerified'] as bool? ?? false,
      isPhoneVerified: data['isPhoneVerified'] as bool? ?? false,
      listingsCount: data['listingsCount'] as int? ?? 0,
      connectionsCount: data['connectionsCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  /// Constructs a [UserModel] from a plain Map (e.g. Firestore set/update).
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      mobile: map['mobile'] as String?,
      city: map['city'] as String?,
      reraNumber: map['reraNumber'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      referralCode: map['referralCode'] as String?,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      isVerified: map['isVerified'] as bool? ?? false,
      isPhoneVerified: map['isPhoneVerified'] as bool? ?? false,
      listingsCount: map['listingsCount'] as int? ?? 0,
      connectionsCount: map['connectionsCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts to a Firestore-compatible Map for writes.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'mobile': mobile,
      'city': city,
      'reraNumber': reraNumber,
      'role': role?.name,
      // Always persist referralCode so it survives profile updates
      'referralCode': effectiveReferralCode,
      'isProfileComplete': isProfileComplete,
      'isVerified': isVerified,
      'isPhoneVerified': isPhoneVerified,
      'listingsCount': listingsCount,
      'connectionsCount': connectionsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
    };
  }

  /// Creates a minimal [UserModel] from a new social sign-in.
  /// Used on first-ever login before profile setup.
  factory UserModel.fromNewSocialLogin({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) {
    // Referral code = first 8 chars of uid, uppercase — deterministic and unique.
    final code = uid.substring(0, 8).toUpperCase();
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
      referralCode: code,
      isProfileComplete: false,
      createdAt: DateTime.now(),
    );
  }

  /// Promotes a domain [AppUser] back to a [UserModel] for data-layer use.
  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
      mobile: user.mobile,
      city: user.city,
      reraNumber: user.reraNumber,
      role: user.role,
      referralCode: user.referralCode,
      isProfileComplete: user.isProfileComplete,
      isVerified: user.isVerified,
      isPhoneVerified: user.isPhoneVerified,
      listingsCount: user.listingsCount,
      connectionsCount: user.connectionsCount,
      createdAt: user.createdAt,
      lastSeen: user.lastSeen,
    );
  }
}
