import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/organisation/data/datasources/organisation_remote_datasource.dart';
import 'package:cpapp/features/organisation/data/repositories/organisation_repository_impl.dart';
import 'package:cpapp/features/organisation/domain/entities/org_invite.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/entities/org_team.dart';
import 'package:cpapp/features/organisation/domain/entities/organisation.dart';
import 'package:cpapp/features/organisation/domain/repositories/organisation_repository.dart';

part 'org_providers.g.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

@riverpod
OrganisationRemoteDataSource orgRemoteDataSource(Ref ref) {
  return OrganisationRemoteDataSourceImpl(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
}

@riverpod
OrganisationRepository orgRepository(Ref ref) {
  return OrganisationRepositoryImpl(
    ds: ref.watch(orgRemoteDataSourceProvider),
  );
}

// ── Current org (from stored orgId) ──────────────────────────────────────────

/// The orgId the app is currently operating in.
/// Null = solo-broker mode.
final currentOrgIdProvider = StateProvider<String?>((ref) => null);

@riverpod
Stream<Organisation> watchCurrentOrg(Ref ref) {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) throw StateError('No org id set');
  return ref.watch(orgRepositoryProvider).watchOrg(orgId);
}

@riverpod
Stream<List<OrgMember>> watchOrgMembers(Ref ref) {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return const Stream.empty();
  return ref.watch(orgRepositoryProvider).watchMembers(orgId);
}

@riverpod
Stream<List<OrgTeam>> watchOrgTeams(Ref ref) {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return const Stream.empty();
  return ref.watch(orgRepositoryProvider).watchTeams(orgId);
}

/// Streams the member IDs that belong to a specific team (from subcollection).
final watchTeamMemberIdsProvider =
    StreamProvider.autoDispose.family<List<String>, String>((ref, teamId) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('org_teams')
      .doc(teamId)
      .collection('team_members')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toList());
});

// ── Current user's member record ──────────────────────────────────────────────

@riverpod
Future<OrgMember?> currentOrgMember(Ref ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (orgId == null || uid == null) return null;
  final result = await ref
      .watch(orgRepositoryProvider)
      .getMemberByUid(orgId: orgId, brokerUid: uid);
  return result.fold((_) => null, (m) => m);
}

// ── Pending invites ───────────────────────────────────────────────────────────

@riverpod
Future<List<OrgInvite>> pendingInvites(Ref ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final result =
      await ref.watch(orgRepositoryProvider).getPendingInvites(orgId);
  return result.fold((_) => [], (list) => list);
}

/// All invites (pending + accepted + revoked) — used by the invite sheet so
/// admins can see when an invited member has joined.
@riverpod
Future<List<OrgInvite>> allOrgInvites(Ref ref) async {
  final orgId = ref.watch(currentOrgIdProvider);
  if (orgId == null) return [];
  final result = await ref.watch(orgRepositoryProvider).getAllInvites(orgId);
  return result.fold((_) => [], (list) => list);
}

/// Team IDs the current member belongs to. Empty for Admin/Agent/solo.
@riverpod
Future<List<String>> callerTeamIds(Ref ref) async {
  final member = await ref.watch(currentOrgMemberProvider.future);
  if (member == null) return [];
  final result =
      await ref.watch(orgRepositoryProvider).getTeamIdsForMember(member.id);
  return result.fold((_) => [], (ids) => ids);
}

// ── Notifiers ─────────────────────────────────────────────────────────────────

@riverpod
class OrgActions extends _$OrgActions {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  OrganisationRepository get _repo => ref.read(orgRepositoryProvider);

  Future<String?> createOrg({
    required String brokerUid,
    required String brokerName,
    required String orgName,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.createOrg(
      brokerUid: brokerUid,
      brokerName: brokerName,
      orgName: orgName,
    );
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return null;
      },
      (org) {
        ref.read(currentOrgIdProvider.notifier).state = org.id;
        state = const AsyncData(null);
        // Fire-and-forget: stamp solo leads with the new orgId.
        _repo.stampExistingLeads(brokerUid: brokerUid, orgId: org.id);
        return org.id;
      },
    );
  }

  Future<bool> sendInvite({
    required String orgId,
    required String orgName,
    required String email,
    required OrgRole role,
    required String invitedByMemberId,
    String? teamId,
    String? mobile,
    bool mobileVerified = false,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.sendInvite(
      orgId: orgId,
      orgName: orgName,
      email: email,
      mobile: mobile,
      role: role,
      invitedByMemberId: invitedByMemberId,
      teamId: teamId,
      mobileVerified: mobileVerified,
    );
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(pendingInvitesProvider);
        ref.invalidate(allOrgInvitesProvider);
        return true;
      },
    );
  }

  /// Looks up a mobile-verified pending invite for [mobile] and auto-accepts it.
  /// Sets [currentOrgIdProvider] and returns welcome info on success, null otherwise.
  Future<({String orgId, String orgName, String adminName})?> acceptInviteByMobile({
    required String mobile,
    required String brokerUid,
    String brokerName = '',
    String? brokerPhotoUrl,
  }) async {
    final member = await _repo.acceptInviteByMobile(
      mobile: mobile,
      brokerUid: brokerUid,
      brokerName: brokerName,
      brokerPhotoUrl: brokerPhotoUrl,
    );
    if (member == null) return null;
    ref.read(currentOrgIdProvider.notifier).state = member.orgId;
    ref.invalidate(allOrgInvitesProvider);
    ref.invalidate(pendingInvitesProvider);
    _repo.stampExistingLeads(brokerUid: brokerUid, orgId: member.orgId);

    // Fetch org name and admin name for the welcome screen.
    String orgName = '';
    String adminName = '';
    try {
      final fs = ref.read(firebaseFirestoreProvider);
      final orgDoc = await fs
          .collection(AppConstants.organisationsCollection)
          .doc(member.orgId)
          .get();
      orgName = (orgDoc.data()?['orgName'] as String?) ?? '';
      final adminUid = (orgDoc.data()?['adminUid'] as String?) ?? '';
      if (adminUid.isNotEmpty) {
        final adminDoc = await fs
            .collection(AppConstants.usersCollection)
            .doc(adminUid)
            .get();
        adminName = (adminDoc.data()?['name'] as String?) ?? '';
      }
    } catch (_) {}

    return (orgId: member.orgId, orgName: orgName, adminName: adminName);
  }

  Future<bool> revokeInvite(String inviteId) async {
    state = const AsyncLoading();
    final result = await _repo.revokeInvite(inviteId);
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        ref.invalidate(pendingInvitesProvider);
        ref.invalidate(allOrgInvitesProvider);
        return true;
      },
    );
  }

  Future<bool> updateMemberRole({
    required String memberId,
    required OrgRole role,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.updateMember(memberId: memberId, role: role);
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> deactivateMember(String memberId) async {
    state = const AsyncLoading();
    final result =
        await _repo.updateMember(memberId: memberId, isActive: false);
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> addMemberToTeam({
    required String teamId,
    required String memberId,
  }) async {
    final orgId = ref.read(currentOrgIdProvider) ?? '';
    final result = await _repo.addMemberToTeam(
      teamId: teamId,
      memberId: memberId,
      orgId: orgId,
    );
    return result.fold((f) => false, (_) => true);
  }

  Future<bool> removeMemberFromTeam({
    required String teamId,
    required String memberId,
  }) async {
    final result = await _repo.removeMemberFromTeam(
      teamId: teamId,
      memberId: memberId,
    );
    return result.fold((f) => false, (_) => true);
  }

  Future<void> setTeamLeadSharing(String orgId, {required bool shared}) async {
    final result = await _repo.updateTeamLeadSharing(orgId, shared: shared);
    result.fold(
      (f) => state = AsyncError(f.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }

  Future<bool> createTeam({
    required String orgId,
    required String teamName,
    String? managerId,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.createTeam(
      orgId: orgId,
      teamName: teamName,
      managerId: managerId,
    );
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> deleteTeam(String teamId) async {
    state = const AsyncLoading();
    final result = await _repo.deleteTeam(teamId);
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> acceptInvite({
    required String token,
    required String brokerUid,
    required String brokerName,
    String? photoUrl,
    String? mobile,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.acceptInvite(
      token: token,
      brokerUid: brokerUid,
      brokerName: brokerName,
      brokerPhotoUrl: photoUrl,
      brokerMobile: mobile,
    );
    return result.fold(
      (f) {
        state = AsyncError(f.message, StackTrace.current);
        return false;
      },
      (member) {
        ref.read(currentOrgIdProvider.notifier).state = member.orgId;
        state = const AsyncData(null);
        // Stamp solo leads with the new orgId.
        _repo.stampExistingLeads(brokerUid: brokerUid, orgId: member.orgId);
        return true;
      },
    );
  }

  Future<void> setOrgFeedMode(String orgId, OrgFeedMode mode) async {
    final result = await _repo.updateOrgFeedMode(orgId, mode);
    result.fold(
      (f) => state = AsyncError(f.message, StackTrace.current),
      (_) => state = const AsyncData(null),
    );
  }
}

// ── Org feed restriction ──────────────────────────────────────────────────────
//
// Returns the admin's UID when the org has switched to "admin only" feed mode
// AND the current user is a non-admin member. Returns null otherwise (no
// restriction applies — everyone sees all listings).

final orgFeedRestrictionProvider = Provider<String?>((ref) {
  final orgAsync = ref.watch(watchCurrentOrgProvider);
  final memberAsync = ref.watch(currentOrgMemberProvider);

  final org = orgAsync.valueOrNull;
  final member = memberAsync.valueOrNull;

  if (org == null || member == null) return null;
  if (org.orgFeedMode != OrgFeedMode.adminOnly) return null;
  if (member.role == OrgRole.admin) return null; // admin is unrestricted

  return org.adminUid;
});
