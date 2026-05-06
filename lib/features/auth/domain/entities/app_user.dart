import 'package:equatable/equatable.dart';
import 'package:cpapp/features/auth/domain/entities/user_role.dart';

/// Core user entity used across the entire domain layer.
/// Immutable — state changes produce new instances.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.photoUrl,
    this.mobile,
    this.city,
    this.reraNumber,
    this.role,
    this.referralCode,
    this.isProfileComplete = false,
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.listingsCount = 0,
    this.connectionsCount = 0,
    this.lastSeen,
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? mobile;
  final String? city;
  final String? reraNumber;
  final UserRole? role;
  /// Unique 8-char code used in referral deep links (e.g. "A1B2C3D4").
  final String? referralCode;
  final bool isProfileComplete;
  final bool isVerified;
  final bool isPhoneVerified;
  final int listingsCount;
  final int connectionsCount;
  final DateTime createdAt;
  final DateTime? lastSeen;

  String get effectiveReferralCode =>
      referralCode ?? uid.substring(0, 8).toUpperCase();

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? mobile,
    String? city,
    String? reraNumber,
    UserRole? role,
    bool clearRole = false,
    String? referralCode,
    bool? isProfileComplete,
    bool? isVerified,
    bool? isPhoneVerified,
    int? listingsCount,
    int? connectionsCount,
    DateTime? lastSeen,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      mobile: mobile ?? this.mobile,
      city: city ?? this.city,
      reraNumber: reraNumber ?? this.reraNumber,
      role: clearRole ? null : (role ?? this.role),
      referralCode: referralCode ?? this.referralCode,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isVerified: isVerified ?? this.isVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      listingsCount: listingsCount ?? this.listingsCount,
      connectionsCount: connectionsCount ?? this.connectionsCount,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        photoUrl,
        mobile,
        city,
        reraNumber,
        role,
        referralCode,
        isProfileComplete,
        isVerified,
        isPhoneVerified,
        listingsCount,
        connectionsCount,
        createdAt,
        lastSeen,
      ];
}
