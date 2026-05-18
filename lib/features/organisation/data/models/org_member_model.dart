import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';

class OrgMemberModel extends OrgMember {
  const OrgMemberModel({
    required super.id,
    required super.orgId,
    required super.brokerUid,
    required super.brokerName,
    required super.role,
    required super.isActive,
    required super.createdAt,
    super.brokerPhotoUrl,
    super.brokerMobile,
    super.reportsTo,
    super.invitedBy,
    super.invitedAt,
    super.joinedAt,
  });

  factory OrgMemberModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return OrgMemberModel(
      id: doc.id,
      orgId: (d['orgId'] as String?) ?? '',
      brokerUid: (d['brokerUid'] as String?) ?? '',
      brokerName: (d['brokerName'] as String?) ?? '',
      brokerPhotoUrl: d['brokerPhotoUrl'] as String?,
      brokerMobile: d['brokerMobile'] as String?,
      role: OrgRole.fromString(d['role'] as String?),
      reportsTo: d['reportsTo'] as String?,
      isActive: (d['isActive'] as bool?) ?? true,
      invitedBy: d['invitedBy'] as String?,
      invitedAt: (d['invitedAt'] as Timestamp?)?.toDate(),
      joinedAt: (d['joinedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'orgId': orgId,
        'brokerUid': brokerUid,
        'brokerName': brokerName,
        'brokerPhotoUrl': brokerPhotoUrl,
        'brokerMobile': brokerMobile,
        'role': role.name,
        'reportsTo': reportsTo,
        'isActive': isActive,
        'invitedBy': invitedBy,
        'invitedAt': invitedAt != null ? Timestamp.fromDate(invitedAt!) : null,
        'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
