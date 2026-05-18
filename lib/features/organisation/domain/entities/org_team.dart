import 'package:equatable/equatable.dart';

class OrgTeam extends Equatable {
  const OrgTeam({
    required this.id,
    required this.orgId,
    required this.teamName,
    required this.createdAt,
    this.managerId,
    this.managerName,
    this.memberCount = 0,
  });

  final String id;
  final String orgId;
  final String teamName;

  /// memberId of the team manager (null = unmanaged).
  final String? managerId;

  /// Denormalised for display without extra fetches.
  final String? managerName;
  final int memberCount;
  final DateTime createdAt;

  OrgTeam copyWith({
    String? teamName,
    String? managerId,
    String? managerName,
    int? memberCount,
  }) {
    return OrgTeam(
      id: id,
      orgId: orgId,
      teamName: teamName ?? this.teamName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, orgId, teamName, managerId, memberCount];
}
