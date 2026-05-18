import 'package:equatable/equatable.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';

enum InviteStatus { pending, accepted, revoked }

class OrgInvite extends Equatable {
  const OrgInvite({
    required this.id,
    required this.orgId,
    required this.orgName,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.token,
    required this.expiresAt,
    required this.status,
    required this.createdAt,
    this.teamId,
    this.mobile,
    this.mobileVerified = false,
  });

  final String id;
  final String orgId;
  final String orgName;
  final String email;
  final String? mobile;
  final OrgRole role;
  final String? teamId;

  /// memberId of the inviter.
  final String invitedBy;

  /// Signed token included in the invite link.
  final String token;
  final DateTime expiresAt;
  final InviteStatus status;
  final DateTime createdAt;
  final bool mobileVerified;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == InviteStatus.pending && !isExpired;

  bool get isMobileInvite => mobile != null && mobile!.isNotEmpty;
  String get displayIdentifier => isMobileInvite ? '+91 $mobile' : email;

  @override
  List<Object?> get props => [id, orgId, email, mobile, role, status, expiresAt];
}
