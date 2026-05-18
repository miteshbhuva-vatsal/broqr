import 'package:equatable/equatable.dart';

enum OrgStatus { active, suspended }

/// Controls what feed content org team members see.
enum OrgFeedMode {
  all,        // default — every broker's listings
  adminOnly;  // team sees only the admin's listings; category filter hidden

  String get firestoreKey => switch (this) {
        OrgFeedMode.all => 'all',
        OrgFeedMode.adminOnly => 'admin_only',
      };

  static OrgFeedMode fromString(String? v) => switch (v) {
        'admin_only' => OrgFeedMode.adminOnly,
        _ => OrgFeedMode.all,
      };
}

class Organisation extends Equatable {
  const Organisation({
    required this.id,
    required this.orgName,
    required this.orgCode,
    required this.adminUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.address,
    this.gstNo,
    this.pan,
    this.memberCount = 0,
    this.orgFeedMode = OrgFeedMode.all,
    this.teamLeadsShared = false,
  });

  final String id;
  final String orgName;

  /// Short slug used in invite links (e.g. "acme-realty").
  final String orgCode;
  final String adminUid;
  final String? logoUrl;
  final String? address;
  final String? gstNo;
  final String? pan;
  final OrgStatus status;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Whether team members see only the admin's listings or everyone's.
  final OrgFeedMode orgFeedMode;

  /// When true all org members see all org leads; when false members see
  /// only their own + explicitly assigned leads (team-isolated mode).
  final bool teamLeadsShared;

  bool get isActive => status == OrgStatus.active;

  Organisation copyWith({
    String? orgName,
    String? orgCode,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
    OrgStatus? status,
    int? memberCount,
    DateTime? updatedAt,
    OrgFeedMode? orgFeedMode,
    bool? teamLeadsShared,
  }) {
    return Organisation(
      id: id,
      orgName: orgName ?? this.orgName,
      orgCode: orgCode ?? this.orgCode,
      adminUid: adminUid,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      gstNo: gstNo ?? this.gstNo,
      pan: pan ?? this.pan,
      status: status ?? this.status,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      orgFeedMode: orgFeedMode ?? this.orgFeedMode,
      teamLeadsShared: teamLeadsShared ?? this.teamLeadsShared,
    );
  }

  @override
  List<Object?> get props =>
      [id, orgName, orgCode, adminUid, status, memberCount, updatedAt, orgFeedMode, teamLeadsShared];
}
