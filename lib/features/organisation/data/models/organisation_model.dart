import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/organisation/domain/entities/organisation.dart';

class OrganisationModel extends Organisation {
  const OrganisationModel({
    required super.id,
    required super.orgName,
    required super.orgCode,
    required super.adminUid,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.logoUrl,
    super.address,
    super.gstNo,
    super.pan,
    super.memberCount,
    super.orgFeedMode,
    super.teamLeadsShared,
  });

  factory OrganisationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return OrganisationModel(
      id: doc.id,
      orgName: (d['orgName'] as String?) ?? '',
      orgCode: (d['orgCode'] as String?) ?? '',
      adminUid: (d['adminUid'] as String?) ?? '',
      logoUrl: d['logoUrl'] as String?,
      address: d['address'] as String?,
      gstNo: d['gstNo'] as String?,
      pan: d['pan'] as String?,
      status: (d['status'] as String?) == 'suspended'
          ? OrgStatus.suspended
          : OrgStatus.active,
      memberCount: (d['memberCount'] as int?) ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orgFeedMode: OrgFeedMode.fromString(d['orgFeedMode'] as String?),
      teamLeadsShared: (d['teamLeadsShared'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'orgName': orgName,
        'orgCode': orgCode,
        'adminUid': adminUid,
        'logoUrl': logoUrl,
        'address': address,
        'gstNo': gstNo,
        'pan': pan,
        'status': status == OrgStatus.suspended ? 'suspended' : 'active',
        'memberCount': memberCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'orgFeedMode': orgFeedMode.firestoreKey,
        'teamLeadsShared': teamLeadsShared,
      };
}
