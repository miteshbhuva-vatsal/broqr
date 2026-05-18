import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/organisation/data/models/org_invite_model.dart';
import 'package:cpapp/features/organisation/data/models/org_member_model.dart';
import 'package:cpapp/features/organisation/data/models/org_team_model.dart';
import 'package:cpapp/features/organisation/data/models/organisation_model.dart';
import 'package:cpapp/features/organisation/domain/entities/org_invite.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/entities/organisation.dart';

abstract interface class OrganisationRemoteDataSource {
  Future<OrganisationModel> createOrg({
    required String brokerUid,
    required String brokerName,
    required String orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  });

  Future<OrganisationModel> getOrg(String orgId);
  Stream<OrganisationModel> watchOrg(String orgId);
  Future<OrganisationModel> updateOrg({
    required String orgId,
    String? orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  });
  Future<void> suspendOrg(String orgId);
  Future<void> updateOrgFeedMode(String orgId, OrgFeedMode mode);
  Future<void> updateTeamLeadSharing(String orgId, {required bool shared});

  Stream<List<OrgMemberModel>> watchMembers(String orgId);
  Future<List<OrgMemberModel>> getMembers(String orgId);
  Future<OrgMemberModel?> getMemberByUid({
    required String orgId,
    required String brokerUid,
  });
  Future<OrgMemberModel> updateMember({
    required String memberId,
    OrgRole? role,
    bool? isActive,
    String? reportsTo,
  });
  Future<void> removeMember(String memberId);

  Stream<List<OrgTeamModel>> watchTeams(String orgId);
  Future<List<OrgTeamModel>> getTeams(String orgId);
  Future<OrgTeamModel> createTeam({
    required String orgId,
    required String teamName,
    String? managerId,
    String? managerName,
  });
  Future<OrgTeamModel> updateTeam({
    required String teamId,
    String? teamName,
    String? managerId,
    String? managerName,
  });
  Future<void> deleteTeam(String teamId);
  Future<void> addMemberToTeam({
    required String teamId,
    required String memberId,
    required String orgId,
  });
  Future<void> removeMemberFromTeam({
    required String teamId,
    required String memberId,
  });
  Future<List<String>> getTeamIdsForMember(String memberId);

  Future<OrgInviteModel> sendInvite({
    required String orgId,
    required String orgName,
    required String email,
    required OrgRole role,
    required String invitedByMemberId,
    String? teamId,
    String? mobile,
    bool mobileVerified = false,
  });
  Future<List<OrgInviteModel>> getPendingInvites(String orgId);
  Future<List<OrgInviteModel>> getAllInvites(String orgId);
  Future<void> revokeInvite(String inviteId);
  Future<OrgMemberModel?> acceptInviteByMobile({
    required String mobile,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
  });
  Future<OrgMemberModel> acceptInvite({
    required String token,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
    String? brokerMobile,
  });

  Future<int> stampExistingLeads({
    required String brokerUid,
    required String orgId,
  });
}

// ── Implementation ────────────────────────────────────────────────────────────

class OrganisationRemoteDataSourceImpl implements OrganisationRemoteDataSource {
  OrganisationRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _orgs =>
      _db.collection(AppConstants.organisationsCollection);
  CollectionReference<Map<String, dynamic>> get _members =>
      _db.collection(AppConstants.orgMembersCollection);
  CollectionReference<Map<String, dynamic>> get _teams =>
      _db.collection(AppConstants.orgTeamsCollection);
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection(AppConstants.orgInvitesCollection);
  CollectionReference<Map<String, dynamic>> get _leads =>
      _db.collection(AppConstants.leadsCollection);

  // ── Org ───────────────────────────────────────────────────────────────────

  @override
  Future<OrganisationModel> createOrg({
    required String brokerUid,
    required String brokerName,
    required String orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  }) async {
    try {
      final orgRef = _orgs.doc();
      final now = DateTime.now();
      final orgCode = _generateOrgCode(orgName);
      // Deterministic member doc ID allows Firestore rules to verify membership
      // without a collection-group query: org_members/{brokerUid}_{orgId}
      final memberRef = _members.doc('${brokerUid}_${orgRef.id}');

      final orgData = {
        'orgName': orgName,
        'orgCode': orgCode,
        'adminUid': brokerUid,
        'logoUrl': logoUrl,
        'address': address,
        'gstNo': gstNo,
        'pan': pan,
        'status': 'active',
        'memberCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final memberData = {
        'orgId': orgRef.id,
        'brokerUid': brokerUid,
        'brokerName': brokerName,
        'role': OrgRole.admin.name,
        'isActive': true,
        'invitedBy': null,
        'invitedAt': null,
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = _db.batch();
      batch.set(orgRef, orgData);
      batch.set(memberRef, memberData);
      // Persist orgId on the user doc so it survives logout/login.
      batch.update(
        _db.collection(AppConstants.usersCollection).doc(brokerUid),
        {'orgId': orgRef.id, 'updatedAt': FieldValue.serverTimestamp()},
      );
      await batch.commit();

      return OrganisationModel(
        id: orgRef.id,
        orgName: orgName,
        orgCode: orgCode,
        adminUid: brokerUid,
        logoUrl: logoUrl,
        address: address,
        gstNo: gstNo,
        pan: pan,
        status: OrgStatus.active,
        memberCount: 1,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw ServerException('Failed to create org: $e');
    }
  }

  @override
  Future<OrganisationModel> getOrg(String orgId) async {
    try {
      final doc = await _orgs.doc(orgId).get();
      if (!doc.exists) throw const ServerException('Org not found');
      return OrganisationModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to get org: $e');
    }
  }

  @override
  Stream<OrganisationModel> watchOrg(String orgId) {
    return _orgs.doc(orgId).snapshots().map((doc) {
      if (!doc.exists) throw const ServerException('Org not found');
      return OrganisationModel.fromFirestore(doc);
    });
  }

  @override
  Future<OrganisationModel> updateOrg({
    required String orgId,
    String? orgName,
    String? logoUrl,
    String? address,
    String? gstNo,
    String? pan,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (orgName != null) updates['orgName'] = orgName;
      if (logoUrl != null) updates['logoUrl'] = logoUrl;
      if (address != null) updates['address'] = address;
      if (gstNo != null) updates['gstNo'] = gstNo;
      if (pan != null) updates['pan'] = pan;
      await _orgs.doc(orgId).update(updates);
      return getOrg(orgId);
    } catch (e) {
      throw ServerException('Failed to update org: $e');
    }
  }

  @override
  Future<void> suspendOrg(String orgId) async {
    try {
      await _orgs.doc(orgId).update({
        'status': 'suspended',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to suspend org: $e');
    }
  }

  @override
  Future<void> updateOrgFeedMode(String orgId, OrgFeedMode mode) async {
    try {
      await _orgs.doc(orgId).update({
        'orgFeedMode': mode.firestoreKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to update org feed mode: $e');
    }
  }

  @override
  Future<void> updateTeamLeadSharing(String orgId, {required bool shared}) async {
    try {
      await _orgs.doc(orgId).update({
        'teamLeadsShared': shared,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException('Failed to update team lead sharing: $e');
    }
  }

  // ── Members ───────────────────────────────────────────────────────────────

  @override
  Stream<List<OrgMemberModel>> watchMembers(String orgId) {
    return _members
        .where('orgId', isEqualTo: orgId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt')
        .limit(300)
        .snapshots()
        .map((snap) => snap.docs.map(OrgMemberModel.fromFirestore).toList());
  }

  @override
  Future<List<OrgMemberModel>> getMembers(String orgId) async {
    try {
      final snap = await _members
          .where('orgId', isEqualTo: orgId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();
      return snap.docs.map(OrgMemberModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException('Failed to get members: $e');
    }
  }

  @override
  Future<OrgMemberModel?> getMemberByUid({
    required String orgId,
    required String brokerUid,
  }) async {
    try {
      final snap = await _members
          .where('orgId', isEqualTo: orgId)
          .where('brokerUid', isEqualTo: brokerUid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return OrgMemberModel.fromFirestore(snap.docs.first);
    } catch (e) {
      throw ServerException('Failed to get member: $e');
    }
  }

  @override
  Future<OrgMemberModel> updateMember({
    required String memberId,
    OrgRole? role,
    bool? isActive,
    String? reportsTo,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (role != null) updates['role'] = role.name;
      if (isActive != null) updates['isActive'] = isActive;
      if (reportsTo != null) updates['reportsTo'] = reportsTo;
      await _members.doc(memberId).update(updates);
      final doc = await _members.doc(memberId).get();
      final member = OrgMemberModel.fromFirestore(doc);

      // Deactivating: remove orgId from user doc so they lose org access
      // immediately on next auth state emission.
      if (isActive == false) {
        await _db
            .collection(AppConstants.usersCollection)
            .doc(member.brokerUid)
            .update({
          'orgId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return member;
    } catch (e) {
      throw ServerException('Failed to update member: $e');
    }
  }

  @override
  Future<void> removeMember(String memberId) async {
    try {
      await _members.doc(memberId).update({'isActive': false});
    } catch (e) {
      throw ServerException('Failed to remove member: $e');
    }
  }

  // ── Teams ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<OrgTeamModel>> watchTeams(String orgId) {
    return _teams
        .where('orgId', isEqualTo: orgId)
        .orderBy('createdAt')
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(OrgTeamModel.fromFirestore).toList());
  }

  @override
  Future<List<OrgTeamModel>> getTeams(String orgId) async {
    try {
      final snap = await _teams
          .where('orgId', isEqualTo: orgId)
          .orderBy('createdAt')
          .get();
      return snap.docs.map(OrgTeamModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException('Failed to get teams: $e');
    }
  }

  @override
  Future<OrgTeamModel> createTeam({
    required String orgId,
    required String teamName,
    String? managerId,
    String? managerName,
  }) async {
    try {
      final ref = _teams.doc();
      final now = DateTime.now();
      final data = {
        'orgId': orgId,
        'teamName': teamName,
        'managerId': managerId,
        'managerName': managerName,
        'memberCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await ref.set(data);
      return OrgTeamModel(
        id: ref.id,
        orgId: orgId,
        teamName: teamName,
        managerId: managerId,
        managerName: managerName,
        createdAt: now,
      );
    } catch (e) {
      throw ServerException('Failed to create team: $e');
    }
  }

  @override
  Future<OrgTeamModel> updateTeam({
    required String teamId,
    String? teamName,
    String? managerId,
    String? managerName,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (teamName != null) updates['teamName'] = teamName;
      if (managerId != null) updates['managerId'] = managerId;
      if (managerName != null) updates['managerName'] = managerName;
      await _teams.doc(teamId).update(updates);
      final doc = await _teams.doc(teamId).get();
      return OrgTeamModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to update team: $e');
    }
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    try {
      await _teams.doc(teamId).delete();
    } catch (e) {
      throw ServerException('Failed to delete team: $e');
    }
  }

  @override
  Future<void> addMemberToTeam({
    required String teamId,
    required String memberId,
    required String orgId,
  }) async {
    try {
      final batch = _db.batch();
      // Subcollection doc (teamId/members/memberId for dedup)
      final subRef = _teams
          .doc(teamId)
          .collection(AppConstants.teamMembersSubcollection)
          .doc(memberId);
      batch.set(subRef, {
        'memberId': memberId,
        'orgId': orgId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      batch
          .update(_teams.doc(teamId), {'memberCount': FieldValue.increment(1)});
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to add member to team: $e');
    }
  }

  @override
  Future<void> removeMemberFromTeam({
    required String teamId,
    required String memberId,
  }) async {
    try {
      final batch = _db.batch();
      final subRef = _teams
          .doc(teamId)
          .collection(AppConstants.teamMembersSubcollection)
          .doc(memberId);
      batch.delete(subRef);
      batch.update(
          _teams.doc(teamId), {'memberCount': FieldValue.increment(-1)},);
      await batch.commit();
    } catch (e) {
      throw ServerException('Failed to remove member from team: $e');
    }
  }

  @override
  Future<List<String>> getTeamIdsForMember(String memberId) async {
    try {
      // CollectionGroup query: all team members subcollections
      final snap = await _db
          .collectionGroup(AppConstants.teamMembersSubcollection)
          .where('memberId', isEqualTo: memberId)
          .get();
      return snap.docs
          .map((d) => d.reference.parent.parent?.id)
          .whereType<String>()
          .toList();
    } catch (e) {
      throw ServerException('Failed to get team ids: $e');
    }
  }

  // ── Invites ───────────────────────────────────────────────────────────────

  @override
  Future<OrgInviteModel> sendInvite({
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
      final ref = _invites.doc();
      final token = _generateToken();
      final now = DateTime.now();
      final expires = now.add(const Duration(hours: 48));
      final data = OrgInviteModel(
        id: ref.id,
        orgId: orgId,
        orgName: orgName,
        email: email,
        mobile: mobile,
        role: role,
        teamId: teamId,
        invitedBy: invitedByMemberId,
        token: token,
        expiresAt: expires,
        status: InviteStatus.pending,
        createdAt: now,
        mobileVerified: mobileVerified,
      );
      await ref.set({
        ...data.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expires),
      });
      return data;
    } catch (e) {
      throw ServerException('Failed to send invite: $e');
    }
  }

  @override
  Future<List<OrgInviteModel>> getPendingInvites(String orgId) async {
    try {
      final snap = await _invites
          .where('orgId', isEqualTo: orgId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map(OrgInviteModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException('Failed to get invites: $e');
    }
  }

  @override
  Future<List<OrgInviteModel>> getAllInvites(String orgId) async {
    try {
      // No orderBy — avoids composite index requirement; sort client-side.
      final snap = await _invites
          .where('orgId', isEqualTo: orgId)
          .get();
      final docs = snap.docs.map(OrgInviteModel.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    } catch (e) {
      throw ServerException('Failed to get invites: $e');
    }
  }

  /// Looks up a pending, OTP-verified invite for [mobile] and auto-accepts it.
  /// Returns the created [OrgMemberModel], or null if no matching invite exists.
  @override
  Future<OrgMemberModel?> acceptInviteByMobile({
    required String mobile,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
  }) async {
    try {
      final snap = await _invites
          .where('mobile', isEqualTo: mobile)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;

      final inviteDoc = snap.docs.first;
      final invite = OrgInviteModel.fromFirestore(inviteDoc);
      if (invite.isExpired) return null;

      // Already a member — return existing record
      final existing = await getMemberByUid(
        orgId: invite.orgId,
        brokerUid: brokerUid,
      );
      if (existing != null) return existing;

      // Fetch broker name from user doc if not supplied
      final nameToUse = brokerName.isNotEmpty
          ? brokerName
          : await _db
              .collection(AppConstants.usersCollection)
              .doc(brokerUid)
              .get()
              .then((d) => (d.data()?['name'] as String?) ?? mobile);

      final memberRef = _members.doc('${brokerUid}_${invite.orgId}');
      final now = DateTime.now();
      final memberData = {
        'orgId': invite.orgId,
        'brokerUid': brokerUid,
        'brokerName': nameToUse,
        'brokerPhotoUrl': brokerPhotoUrl,
        'brokerMobile': mobile,
        'role': invite.role.name,
        'isActive': true,
        'invitedBy': invite.invitedBy,
        'invitedAt': inviteDoc.data()['createdAt'],
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = _db.batch();
      batch.set(memberRef, memberData);
      batch.update(inviteDoc.reference, {'status': 'accepted'});
      batch.update(
          _orgs.doc(invite.orgId), {'memberCount': FieldValue.increment(1)},);
      batch.update(
        _db.collection(AppConstants.usersCollection).doc(brokerUid),
        {'orgId': invite.orgId, 'updatedAt': FieldValue.serverTimestamp()},
      );

      if (invite.teamId != null) {
        final subRef = _teams
            .doc(invite.teamId!)
            .collection(AppConstants.teamMembersSubcollection)
            .doc(memberRef.id);
        batch.set(subRef, {
          'memberId': memberRef.id,
          'orgId': invite.orgId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        batch.update(_teams.doc(invite.teamId!),
            {'memberCount': FieldValue.increment(1)},);
      }

      await batch.commit();

      return OrgMemberModel(
        id: memberRef.id,
        orgId: invite.orgId,
        brokerUid: brokerUid,
        brokerName: nameToUse,
        brokerPhotoUrl: brokerPhotoUrl,
        brokerMobile: mobile,
        role: invite.role,
        isActive: true,
        invitedBy: invite.invitedBy,
        invitedAt: invite.createdAt,
        joinedAt: now,
        createdAt: now,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    try {
      await _invites.doc(inviteId).update({'status': 'revoked'});
    } catch (e) {
      throw ServerException('Failed to revoke invite: $e');
    }
  }

  @override
  Future<OrgMemberModel> acceptInvite({
    required String token,
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
    String? brokerMobile,
  }) async {
    try {
      // Find the invite by token
      final inviteSnap = await _invites
          .where('token', isEqualTo: token)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (inviteSnap.docs.isEmpty) {
        throw const ServerException('Invite not found or already used');
      }
      final inviteDoc = inviteSnap.docs.first;
      final invite = OrgInviteModel.fromFirestore(inviteDoc);

      if (invite.isExpired) {
        throw const ServerException('Invite has expired');
      }

      // Check not already a member
      final existing = await getMemberByUid(
        orgId: invite.orgId,
        brokerUid: brokerUid,
      );
      if (existing != null) throw const ServerException('Already a member');

      // Deterministic member doc ID mirrors the createOrg pattern.
      final memberRef = _members.doc('${brokerUid}_${invite.orgId}');
      final now = DateTime.now();

      final memberData = {
        'orgId': invite.orgId,
        'brokerUid': brokerUid,
        'brokerName': brokerName,
        'brokerPhotoUrl': brokerPhotoUrl,
        'brokerMobile': brokerMobile,
        'role': invite.role.name,
        'isActive': true,
        'invitedBy': invite.invitedBy,
        'invitedAt': inviteDoc.data()['createdAt'],
        'joinedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = _db.batch();
      batch.set(memberRef, memberData);
      batch.update(inviteDoc.reference, {'status': 'accepted'});
      batch.update(
          _orgs.doc(invite.orgId), {'memberCount': FieldValue.increment(1)},);
      // Persist orgId on the user doc so it survives logout/login.
      batch.update(
        _db.collection(AppConstants.usersCollection).doc(brokerUid),
        {'orgId': invite.orgId, 'updatedAt': FieldValue.serverTimestamp()},
      );

      // Auto-assign to team if invite specified one
      if (invite.teamId != null) {
        final subRef = _teams
            .doc(invite.teamId!)
            .collection(AppConstants.teamMembersSubcollection)
            .doc(memberRef.id);
        batch.set(subRef, {
          'memberId': memberRef.id,
          'orgId': invite.orgId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        batch.update(_teams.doc(invite.teamId!),
            {'memberCount': FieldValue.increment(1)},);
      }

      await batch.commit();

      return OrgMemberModel(
        id: memberRef.id,
        orgId: invite.orgId,
        brokerUid: brokerUid,
        brokerName: brokerName,
        brokerPhotoUrl: brokerPhotoUrl,
        brokerMobile: brokerMobile,
        role: invite.role,
        isActive: true,
        invitedBy: invite.invitedBy,
        invitedAt: invite.createdAt,
        joinedAt: now,
        createdAt: now,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to accept invite: $e');
    }
  }

  // ── Upgrade ───────────────────────────────────────────────────────────────

  @override
  Future<int> stampExistingLeads({
    required String brokerUid,
    required String orgId,
  }) async {
    try {
      final snap = await _leads
          .where('ownerUid', isEqualTo: brokerUid)
          .where('orgId', isNull: true)
          .get();
      if (snap.docs.isEmpty) return 0;

      // Firestore batch limit = 500
      var count = 0;
      for (var i = 0; i < snap.docs.length; i += 499) {
        final chunk = snap.docs.sublist(i, min(i + 499, snap.docs.length));
        final batch = _db.batch();
        for (final doc in chunk) {
          batch.update(doc.reference, {'orgId': orgId});
          count++;
        }
        await batch.commit();
      }
      return count;
    } catch (e) {
      throw ServerException('Failed to stamp leads: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _generateOrgCode(String orgName) {
    final slug = orgName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final suffix = _randomAlphaNum(4);
    return '${slug.substring(0, min(slug.length, 12))}-$suffix';
  }

  String _generateToken() => _randomAlphaNum(32);

  static const _chars =
      'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  String _randomAlphaNum(int length) {
    final rng = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => _chars.codeUnitAt(rng.nextInt(_chars.length)),),
    );
  }
}
