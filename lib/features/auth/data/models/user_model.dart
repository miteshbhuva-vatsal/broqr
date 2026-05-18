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
    super.accountType,
    super.companyName,
    super.address,
    super.gstNo,
    super.orgId,
    super.dealCategories,
    super.propertyTypes,
    super.workingAreas,
    super.memberships,
    super.clienteleBase,
    super.isProfilePublic,
    super.hasConfirmedAccountType,
    super.hasSetupTeam,
    super.userPersona,
    super.userSubType,
    super.hasCompletedOnboarding,
    super.preferredDealTypes,
    super.preferredPropertyTypes,
  });

  /// Constructs a [UserModel] from a Firestore document snapshot.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
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
      accountType: data['accountType'] as String? ?? 'individual',
      companyName: data['companyName'] as String?,
      address: data['address'] as String?,
      gstNo: data['gstNo'] as String?,
      orgId: data['orgId'] as String?,
      dealCategories: List<String>.from(data['dealCategories'] as List? ?? []),
      propertyTypes: List<String>.from(data['propertyTypes'] as List? ?? []),
      workingAreas: List<String>.from(data['workingAreas'] as List? ?? []),
      memberships: List<String>.from(data['memberships'] as List? ?? []),
      clienteleBase: data['clienteleBase'] as String?,
      isProfilePublic: data['isProfilePublic'] as bool? ?? true,
      hasConfirmedAccountType: data['hasConfirmedAccountType'] as bool? ?? false,
      hasSetupTeam: data['hasSetupTeam'] as bool? ?? false,
      userPersona: data['userPersona'] as String? ?? '',
      userSubType: data['userSubType'] as String? ?? '',
      hasCompletedOnboarding: data['hasCompletedOnboarding'] as bool? ?? false,
      preferredDealTypes: List<String>.from(data['preferredDealTypes'] as List? ?? []),
      preferredPropertyTypes: List<String>.from(data['preferredPropertyTypes'] as List? ?? []),
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
      accountType: map['accountType'] as String? ?? 'individual',
      companyName: map['companyName'] as String?,
      address: map['address'] as String?,
      gstNo: map['gstNo'] as String?,
      orgId: map['orgId'] as String?,
      dealCategories: List<String>.from(map['dealCategories'] as List? ?? []),
      propertyTypes: List<String>.from(map['propertyTypes'] as List? ?? []),
      workingAreas: List<String>.from(map['workingAreas'] as List? ?? []),
      memberships: List<String>.from(map['memberships'] as List? ?? []),
      clienteleBase: map['clienteleBase'] as String?,
      isProfilePublic: map['isProfilePublic'] as bool? ?? true,
      hasConfirmedAccountType: map['hasConfirmedAccountType'] as bool? ?? false,
      hasSetupTeam: map['hasSetupTeam'] as bool? ?? false,
      userPersona: map['userPersona'] as String? ?? '',
      userSubType: map['userSubType'] as String? ?? '',
      hasCompletedOnboarding: map['hasCompletedOnboarding'] as bool? ?? false,
      preferredDealTypes: List<String>.from(map['preferredDealTypes'] as List? ?? []),
      preferredPropertyTypes: List<String>.from(map['preferredPropertyTypes'] as List? ?? []),
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
      'referralCode': effectiveReferralCode,
      'isProfileComplete': isProfileComplete,
      'isVerified': isVerified,
      'isPhoneVerified': isPhoneVerified,
      'listingsCount': listingsCount,
      'connectionsCount': connectionsCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'accountType': accountType,
      if (companyName != null) 'companyName': companyName,
      if (address != null) 'address': address,
      if (gstNo != null) 'gstNo': gstNo,
      if (orgId != null) 'orgId': orgId,
      'dealCategories': dealCategories,
      'propertyTypes': propertyTypes,
      'workingAreas': workingAreas,
      'memberships': memberships,
      if (clienteleBase != null) 'clienteleBase': clienteleBase,
      'isProfilePublic': isProfilePublic,
      'hasConfirmedAccountType': hasConfirmedAccountType,
      'hasSetupTeam': hasSetupTeam,
      'userPersona': userPersona,
      'userSubType': userSubType,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'preferredDealTypes': preferredDealTypes,
      'preferredPropertyTypes': preferredPropertyTypes,
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
      accountType: user.accountType,
      companyName: user.companyName,
      address: user.address,
      gstNo: user.gstNo,
      orgId: user.orgId,
      dealCategories: user.dealCategories,
      propertyTypes: user.propertyTypes,
      workingAreas: user.workingAreas,
      memberships: user.memberships,
      clienteleBase: user.clienteleBase,
      isProfilePublic: user.isProfilePublic,
      hasConfirmedAccountType: user.hasConfirmedAccountType,
      hasSetupTeam: user.hasSetupTeam,
      userPersona: user.userPersona,
      userSubType: user.userSubType,
      hasCompletedOnboarding: user.hasCompletedOnboarding,
      preferredDealTypes: user.preferredDealTypes,
      preferredPropertyTypes: user.preferredPropertyTypes,
    );
  }
}
