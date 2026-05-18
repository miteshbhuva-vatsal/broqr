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
    this.accountType = 'individual',
    this.companyName,
    this.address,
    this.gstNo,
    this.orgId,
    this.dealCategories = const [],
    this.propertyTypes = const [],
    this.workingAreas = const [],
    this.memberships = const [],
    this.clienteleBase,
    this.isProfilePublic = true,
    this.hasConfirmedAccountType = false,
    this.hasSetupTeam = false,
    this.userPersona = '',
    this.userSubType = '',
    this.hasCompletedOnboarding = false,
    this.preferredDealTypes = const [],
    this.preferredPropertyTypes = const [],
  });

  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? mobile;
  final String? city;
  final String? reraNumber;
  final UserRole? role;

  /// 'individual' or 'organisation'
  final String accountType;
  final String? companyName;
  final String? address;
  final String? gstNo;

  /// Org this user belongs to (set after createOrg or acceptInvite).
  final String? orgId;
  /// Unique 8-char code used in referral deep links (e.g. "A1B2C3D4").
  final String? referralCode;

  /// Deal categories the broker works in (ListingCategory.name values).
  final List<String> dealCategories;

  /// Property types the broker specialises in (PropertyType.firestoreKey values).
  final List<String> propertyTypes;

  /// Preferred working areas / neighbourhoods within the broker's city.
  final List<String> workingAreas;

  /// Professional memberships, e.g. NAR India, CREDAI, NAREDCO.
  final List<String> memberships;

  /// Free-text description of the broker's typical client base.
  final String? clienteleBase;

  /// When false: mobile number is hidden and Call/WhatsApp buttons are disabled.
  final bool isProfilePublic;

  /// True once the user has explicitly chosen their account type via the CRM prompt.
  final bool hasConfirmedAccountType;

  /// True once a team-plan seller has visited the team setup (org members) screen.
  final bool hasSetupTeam;

  /// 'buyer' | 'seller' | '' (not yet selected)
  final String userPersona;

  /// buyer: 'enduser' | 'investor'  /  seller: 'owner' | 'broker' | 'builder' | 'investor'
  final String userSubType;

  /// True once buyer completes the property-preference filter onboarding step.
  final bool hasCompletedOnboarding;

  /// Buyer's preferred deal types chosen during onboarding (e.g. 'Buy', 'Rent').
  final List<String> preferredDealTypes;

  /// Buyer's preferred property types chosen during onboarding.
  final List<String> preferredPropertyTypes;

  bool get isBuyer  => userPersona == 'buyer';
  bool get isSeller => userPersona == 'seller';
  bool get hasPersona => userPersona.isNotEmpty;

  final bool isProfileComplete;
  final bool isVerified;
  final bool isPhoneVerified;
  final int listingsCount;
  final int connectionsCount;
  final DateTime createdAt;
  final DateTime? lastSeen;

  String get effectiveReferralCode =>
      referralCode ?? uid.substring(0, 8).toUpperCase();

  bool get isOrganisation => accountType == 'organisation';

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
    String? accountType,
    String? companyName,
    String? address,
    String? gstNo,
    String? orgId,
    bool clearOrgId = false,
    List<String>? dealCategories,
    List<String>? propertyTypes,
    List<String>? workingAreas,
    List<String>? memberships,
    String? clienteleBase,
    bool clearClienteleBase = false,
    bool? isProfilePublic,
    bool? hasConfirmedAccountType,
    bool? hasSetupTeam,
    String? userPersona,
    String? userSubType,
    bool? hasCompletedOnboarding,
    List<String>? preferredDealTypes,
    List<String>? preferredPropertyTypes,
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
      accountType: accountType ?? this.accountType,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      gstNo: gstNo ?? this.gstNo,
      orgId: clearOrgId ? null : (orgId ?? this.orgId),
      dealCategories: dealCategories ?? this.dealCategories,
      propertyTypes: propertyTypes ?? this.propertyTypes,
      workingAreas: workingAreas ?? this.workingAreas,
      memberships: memberships ?? this.memberships,
      clienteleBase:
          clearClienteleBase ? null : (clienteleBase ?? this.clienteleBase),
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      hasConfirmedAccountType: hasConfirmedAccountType ?? this.hasConfirmedAccountType,
      hasSetupTeam: hasSetupTeam ?? this.hasSetupTeam,
      userPersona: userPersona ?? this.userPersona,
      userSubType: userSubType ?? this.userSubType,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      preferredDealTypes: preferredDealTypes ?? this.preferredDealTypes,
      preferredPropertyTypes: preferredPropertyTypes ?? this.preferredPropertyTypes,
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
        accountType,
        companyName,
        address,
        gstNo,
        orgId,
        dealCategories,
        propertyTypes,
        workingAreas,
        memberships,
        clienteleBase,
        isProfilePublic,
        hasConfirmedAccountType,
        hasSetupTeam,
        userPersona,
        userSubType,
        hasCompletedOnboarding,
        preferredDealTypes,
        preferredPropertyTypes,
      ];
}
