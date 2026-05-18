import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/organisation/domain/entities/org_team.dart';

class OrgTeamModel extends OrgTeam {
  const OrgTeamModel({
    required super.id,
    required super.orgId,
    required super.teamName,
    required super.createdAt,
    super.managerId,
    super.managerName,
    super.memberCount,
  });

  factory OrgTeamModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return OrgTeamModel(
      id: doc.id,
      orgId: (d['orgId'] as String?) ?? '',
      teamName: (d['teamName'] as String?) ?? '',
      managerId: d['managerId'] as String?,
      managerName: d['managerName'] as String?,
      memberCount: (d['memberCount'] as int?) ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'orgId': orgId,
        'teamName': teamName,
        'managerId': managerId,
        'managerName': managerName,
        'memberCount': memberCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
