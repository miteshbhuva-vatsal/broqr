import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/organisation/domain/entities/org_invite.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/entities/org_team.dart';
import 'package:cpapp/features/organisation/domain/entities/organisation.dart';

abstract interface class OrganisationRepository {
  // ── Organisation ──────────────────────────────────────────────────────────

  /// Creates a new org; caller automatically becomes admin.
  Future<Either<Failure, Organisation>> createOrg({
    required String brokerUid,
    required String brokerName,
    required String orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  });

  Future<Either<Failure, Organisation>> getOrg(String orgId);
  Stream<Organisation> watchOrg(String orgId);

  Future<Either<Failure, Organisation>> updateOrg({
    required String orgId,
    String? orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  });

  Future<Either<Failure, Unit>> suspendOrg(String orgId);
  Future<Either<Failure, Unit>> updateOrgFeedMode(String orgId, OrgFeedMode mode);
  Future<Either<Failure, Unit>> updateTeamLeadSharing(String orgId, {required bool shared});

  // ── Members ───────────────────────────────────────────────────────────────

  Stream<List<OrgMember>> watchMembers(String orgId);
  Future<Either<Failure, List<OrgMember>>> getMembers(String orgId);

  Future<Either<Failure, OrgMember?>> getMemberByUid({
    required String orgId,
    required String brokerUid,
  });

  Future<Either<Failure, OrgMember>> updateMember({
    required String memberId,
    OrgRole? role,
    bool? isActive,
    String? reportsTo,
  });

  Future<Either<Failure, Unit>> removeMember(String memberId);

  // ── Teams ─────────────────────────────────────────────────────────────────

  Stream<List<OrgTeam>> watchTeams(String orgId);
  Future<Either<Failure, List<OrgTeam>>> getTeams(String orgId);

  Future<Either<Failure, OrgTeam>> createTeam({
    required String orgId,
    required String teamName,
    String? managerId,
  });

  Future<Either<Failure, OrgTeam>> updateTeam({
    required String teamId,
    String? teamName,
    String? managerId,
  });

  Future<Either<Failure, Unit>> deleteTeam(String teamId);

  Future<Either<Failure, Unit>> addMemberToTeam({
    required String teamId,
    required String memberId,
    required String orgId,
  });

  Future<Either<Failure, Unit>> removeMemberFromTeam({
    required String teamId,
    required String memberId,
  });

  Future<Either<Failure, List<String>>> getTeamIdsForMember(String memberId);

  // ── Invites ───────────────────────────────────────────────────────────────

  Future<Either<Failure, OrgInvite>> sendInvite({
    required String orgId,
    required String orgName,
    required String email,
    required OrgRole role,
    required String invitedByMemberId,
    String? teamId,
    String? mobile,
    bool mobileVerified = false,
  });

  Future<Either<Failure, List<OrgInvite>>> getPendingInvites(String orgId);
  Future<Either<Failure, List<OrgInvite>>> getAllInvites(String orgId);

  Future<Either<Failure, Unit>> revokeInvite(String inviteId);

  /// Accept an invite and join the org. Returns the new OrgMember.
  Future<Either<Failure, OrgMember>> acceptInvite({
    required String token,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
    String? brokerMobile,
  });

  /// Auto-join org from a mobile-verified invite. Returns null if no invite found.
  Future<OrgMember?> acceptInviteByMobile({
    required String mobile,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
  });

  // ── Upgrade (solo → org) ──────────────────────────────────────────────────

  /// Stamps all solo leads belonging to [brokerUid] with [orgId].
  Future<Either<Failure, int>> stampExistingLeads({
    required String brokerUid,
    required String orgId,
  });
}
