import 'package:equatable/equatable.dart';

enum OrgRole {
  admin,
  manager,
  agent,
  view;

  String get label => switch (this) {
        OrgRole.admin => 'Admin',
        OrgRole.manager => 'Manager',
        OrgRole.agent => 'Sales Executive',
        OrgRole.view => 'Telecaller',
      };

  static OrgRole fromString(String? v) => switch (v) {
        'admin' => OrgRole.admin,
        'manager' => OrgRole.manager,
        'agent' => OrgRole.agent,
        'view' => OrgRole.view,
        _ => OrgRole.agent,
      };
}

/// Lead visibility scope derived from an OrgRole.
enum LeadScope {
  own, // agent: only leads owned by this member
  team, // manager: all leads in own teams
  allOrg, // admin: all org leads
}

class OrgMember extends Equatable {
  const OrgMember({
    required this.id,
    required this.orgId,
    required this.brokerUid,
    required this.brokerName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.brokerPhotoUrl,
    this.brokerMobile,
    this.reportsTo,
    this.invitedBy,
    this.invitedAt,
    this.joinedAt,
  });

  final String id;
  final String orgId;
  final String brokerUid;
  final String brokerName;
  final String? brokerPhotoUrl;
  final String? brokerMobile;
  final OrgRole role;

  /// memberId of this member's manager (null for admin / unassigned).
  final String? reportsTo;
  final bool isActive;

  /// memberId of the member who sent the invite.
  final String? invitedBy;
  final DateTime? invitedAt;
  final DateTime? joinedAt;
  final DateTime createdAt;

  OrgMember copyWith({
    OrgRole? role,
    bool? isActive,
    String? reportsTo,
    String? brokerName,
    String? brokerPhotoUrl,
    String? brokerMobile,
    DateTime? joinedAt,
  }) {
    return OrgMember(
      id: id,
      orgId: orgId,
      brokerUid: brokerUid,
      brokerName: brokerName ?? this.brokerName,
      brokerPhotoUrl: brokerPhotoUrl ?? this.brokerPhotoUrl,
      brokerMobile: brokerMobile ?? this.brokerMobile,
      role: role ?? this.role,
      reportsTo: reportsTo ?? this.reportsTo,
      isActive: isActive ?? this.isActive,
      invitedBy: invitedBy,
      invitedAt: invitedAt,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, orgId, brokerUid, role, isActive, reportsTo];
}
