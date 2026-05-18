import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/organisation/data/datasources/organisation_remote_datasource.dart';
import 'package:cpapp/features/organisation/domain/entities/org_invite.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/entities/org_team.dart';
import 'package:cpapp/features/organisation/domain/entities/organisation.dart';
import 'package:cpapp/features/organisation/domain/repositories/organisation_repository.dart';

class OrganisationRepositoryImpl implements OrganisationRepository {
  const OrganisationRepositoryImpl({required OrganisationRemoteDataSource ds})
      : _ds = ds;

  final OrganisationRemoteDataSource _ds;

  // ── Org ───────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Organisation>> createOrg({
    required String brokerUid,
    required String brokerName,
    required String orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  }) async {
    try {
      return Right(await _ds.createOrg(
        brokerUid: brokerUid,
        brokerName: brokerName,
        orgName: orgName,
        logoUrl: logoUrl,
        address: address,
        gstNo: gstNo,
        pan: pan,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Organisation>> getOrg(String orgId) async {
    try {
      return Right(await _ds.getOrg(orgId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<Organisation> watchOrg(String orgId) => _ds.watchOrg(orgId);

  @override
  Future<Either<Failure, Organisation>> updateOrg({
    required String orgId,
    String? orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  }) async {
    try {
      return Right(await _ds.updateOrg(
        orgId: orgId,
        orgName: orgName,
        logoUrl: logoUrl,
        address: address,
        gstNo: gstNo,
        pan: pan,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> suspendOrg(String orgId) async {
    try {
      await _ds.suspendOrg(orgId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateOrgFeedMode(String orgId, OrgFeedMode mode) async {
    try {
      await _ds.updateOrgFeedMode(orgId, mode);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTeamLeadSharing(String orgId, {required bool shared}) async {
    try {
      await _ds.updateTeamLeadSharing(orgId, shared: shared);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── Members ───────────────────────────────────────────────────────────────

  @override
  Stream<List<OrgMember>> watchMembers(String orgId) =>
      _ds.watchMembers(orgId).map((list) => list.cast<OrgMember>());

  @override
  Future<Either<Failure, List<OrgMember>>> getMembers(String orgId) async {
    try {
      return Right(await _ds.getMembers(orgId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrgMember?>> getMemberByUid({
    required String orgId,
    required String brokerUid,
  }) async {
    try {
      return Right(
          await _ds.getMemberByUid(orgId: orgId, brokerUid: brokerUid),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrgMember>> updateMember({
    required String memberId,
    OrgRole? role,
    bool? isActive,
    String? reportsTo,
  }) async {
    try {
      return Right(await _ds.updateMember(
        memberId: memberId,
        role: role,
        isActive: isActive,
        reportsTo: reportsTo,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMember(String memberId) async {
    try {
      await _ds.removeMember(memberId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── Teams ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<OrgTeam>> watchTeams(String orgId) => _ds.watchTeams(orgId);

  @override
  Future<Either<Failure, List<OrgTeam>>> getTeams(String orgId) async {
    try {
      return Right(await _ds.getTeams(orgId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrgTeam>> createTeam({
    required String orgId,
    required String teamName,
    String? managerId,
  }) async {
    try {
      return Right(await _ds.createTeam(
        orgId: orgId,
        teamName: teamName,
        managerId: managerId,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrgTeam>> updateTeam({
    required String teamId,
    String? teamName,
    String? managerId,
  }) async {
    try {
      return Right(await _ds.updateTeam(
        teamId: teamId,
        teamName: teamName,
        managerId: managerId,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTeam(String teamId) async {
    try {
      await _ds.deleteTeam(teamId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> addMemberToTeam({
    required String teamId,
    required String memberId,
    required String orgId,
  }) async {
    try {
      await _ds.addMemberToTeam(
        teamId: teamId,
        memberId: memberId,
        orgId: orgId,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeMemberFromTeam({
    required String teamId,
    required String memberId,
  }) async {
    try {
      await _ds.removeMemberFromTeam(teamId: teamId, memberId: memberId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getTeamIdsForMember(
      String memberId,) async {
    try {
      return Right(await _ds.getTeamIdsForMember(memberId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // ── Invites ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, OrgInvite>> sendInvite({
    required String orgId,
    required String orgName,
    required String email,
    required OrgRole role,
    required String invitedByMemberId,
    String? teamId,
    String? mobile,
    bool mobileVerified = false,
  }) async {
    try {
      return Right(await _ds.sendInvite(
        orgId: orgId,
        orgName: orgName,
        email: email,
        mobile: mobile,
        role: role,
        invitedByMemberId: invitedByMemberId,
        teamId: teamId,
        mobileVerified: mobileVerified,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrgInvite>>> getPendingInvites(
      String orgId,) async {
    try {
      return Right(await _ds.getPendingInvites(orgId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<OrgInvite>>> getAllInvites(String orgId) async {
    try {
      return Right(await _ds.getAllInvites(orgId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<OrgMember?> acceptInviteByMobile({
    required String mobile,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
  }) =>
      _ds.acceptInviteByMobile(
        mobile: mobile,
        brokerUid: brokerUid,
        brokerName: brokerName,
        brokerPhotoUrl: brokerPhotoUrl,
      );

  @override
  Future<Either<Failure, Unit>> revokeInvite(String inviteId) async {
    try {
      await _ds.revokeInvite(inviteId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrgMember>> acceptInvite({
    required String token,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
    String? brokerMobile,
  }) async {
    try {
      return Right(await _ds.acceptInvite(
        token: token,
        brokerUid: brokerUid,
        brokerName: brokerName,
        brokerPhotoUrl: brokerPhotoUrl,
        brokerMobile: brokerMobile,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> stampExistingLeads({
    required String brokerUid,
    required String orgId,
  }) async {
    try {
      return Right(
          await _ds.stampExistingLeads(brokerUid: brokerUid, orgId: orgId),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
