import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/organisation/domain/entities/org_invite.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';

class OrgInviteModel extends OrgInvite {
  const OrgInviteModel({
    required super.id,
    required super.orgId,
    required super.orgName,
    required super.email,
    required super.role,
    required super.invitedBy,
    required super.token,
    required super.expiresAt,
    required super.status,
    required super.createdAt,
    super.teamId,
    super.mobile,
    super.mobileVerified = false,
  });

  factory OrgInviteModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final statusStr = d['status'] as String?;
    final status = statusStr == 'accepted'
        ? InviteStatus.accepted
        : statusStr == 'revoked'
            ? InviteStatus.revoked
            : InviteStatus.pending;

    return OrgInviteModel(
      id: doc.id,
      orgId: (d['orgId'] as String?) ?? '',
      orgName: (d['orgName'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      mobile: d['mobile'] as String?,
      role: OrgRole.fromString(d['role'] as String?),
      teamId: d['teamId'] as String?,
      invitedBy: (d['invitedBy'] as String?) ?? '',
      token: (d['token'] as String?) ?? '',
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: status,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mobileVerified: (d['mobileVerified'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'orgId': orgId,
        'orgName': orgName,
        'email': email,
        if (mobile != null) 'mobile': mobile,
        'mobileVerified': mobileVerified,
        'role': role.name,
        'teamId': teamId,
        'invitedBy': invitedBy,
        'token': token,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
