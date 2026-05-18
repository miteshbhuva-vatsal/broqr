import 'package:cpapp/features/organisation/domain/entities/org_member.dart';

/// Pure, stateless permission matrix.
/// Every check is derived from (caller role, target context) — never from
/// client-supplied strings. The Flutter layer calls these before attempting
/// any Firestore write; Firestore rules enforce the same matrix server-side
/// via custom claims.
abstract final class OrgPermissionService {
  // ── Lead visibility ────────────────────────────────────────────────────────

  static bool canViewOwnLeads(OrgRole role) => true;

  static bool canViewTeamLeads(OrgRole role) =>
      role == OrgRole.admin || role == OrgRole.manager;

  static bool canViewAllOrgLeads(OrgRole role) => role == OrgRole.admin;

  /// Returns the broadest scope this role can see.
  static LeadScope getLeadScope(OrgRole role) {
    if (role == OrgRole.admin) return LeadScope.allOrg;
    if (role == OrgRole.manager) return LeadScope.team;
    return LeadScope.own;
  }

  // ── Lead CRUD ──────────────────────────────────────────────────────────────

  static bool canAddLead(OrgRole role) => role != OrgRole.view;

  static bool canEditOwnLead(OrgRole role) => role != OrgRole.view;

  /// Manager can edit any lead within their team; admin can edit any lead.
  static bool canEditTeamLead(OrgRole role) =>
      role == OrgRole.admin || role == OrgRole.manager;

  /// Soft-delete: manager (own team) or admin.
  static bool canDeleteLead(OrgRole role) =>
      role == OrgRole.admin || role == OrgRole.manager;

  // ── Lead reassignment ──────────────────────────────────────────────────────

  static bool canReassignWithinTeam(OrgRole role) =>
      role == OrgRole.admin || role == OrgRole.manager;

  static bool canReassignAcrossTeams(OrgRole role) => role == OrgRole.admin;

  // ── Lead activities / remarks ──────────────────────────────────────────────

  static bool canViewLeadActivities(OrgRole role) => true;

  /// Agents can add remarks only to their own leads.
  static bool canAddActivity(OrgRole role) => role != OrgRole.view;

  // ── Member management ──────────────────────────────────────────────────────

  /// Admin can invite any role; manager can only invite agent / view.
  static bool canInviteRole(OrgRole callerRole, OrgRole targetRole) {
    if (callerRole == OrgRole.admin) return true;
    if (callerRole == OrgRole.manager) {
      return targetRole == OrgRole.agent || targetRole == OrgRole.view;
    }
    return false;
  }

  static bool canChangeMemberRole(OrgRole role) => role == OrgRole.admin;

  static bool canDeactivateMember(OrgRole role) => role == OrgRole.admin;

  static bool canViewMemberDirectory(OrgRole role) =>
      role == OrgRole.admin || role == OrgRole.manager;

  // ── Team management ────────────────────────────────────────────────────────

  static bool canCreateTeam(OrgRole role) => role == OrgRole.admin;

  static bool canEditTeam(OrgRole role) => role == OrgRole.admin;

  static bool canAddMemberToTeam(OrgRole role) =>
      role == OrgRole.admin || role == OrgRole.manager;

  // ── Reports ────────────────────────────────────────────────────────────────

  static bool canViewOrgReports(OrgRole role) => role == OrgRole.admin;

  static bool canViewTeamReports(OrgRole role) =>
      role == OrgRole.admin || role == OrgRole.manager;

  static bool canViewOwnPerformance(OrgRole role) => role != OrgRole.view;

  // ── Org settings ──────────────────────────────────────────────────────────

  static bool canEditOrgProfile(OrgRole role) => role == OrgRole.admin;

  static bool canSuspendOrg(OrgRole role) => role == OrgRole.admin;

  static bool canTransferAdmin(OrgRole role) => role == OrgRole.admin;

  // ── Context-aware lead check ───────────────────────────────────────────────

  /// Returns true if [caller] may write to a lead owned by [leadOwnerMemberId]
  /// in team [leadTeamId]. Pass null if not applicable.
  static bool canWriteLead({
    required OrgMember caller,
    required String? leadOwnerMemberId,
    required String? leadTeamId,
    required List<String> callerTeamIds,
  }) {
    if (caller.role == OrgRole.admin) return true;
    if (caller.role == OrgRole.view) return false;

    // Agent: own leads only.
    if (caller.role == OrgRole.agent) {
      return leadOwnerMemberId == caller.id;
    }

    // Manager: any lead in own team.
    if (caller.role == OrgRole.manager) {
      if (leadOwnerMemberId == caller.id) return true;
      return leadTeamId != null && callerTeamIds.contains(leadTeamId);
    }

    return false;
  }
}
