import 'package:flutter/material.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/services/org_permission_service.dart';

class OrgPermissionsScreen extends StatelessWidget {
  const OrgPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Roles & Permissions'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _intro(),
          const SizedBox(height: 16),
          for (final role in OrgRole.values) ...[
            _RoleCard(role: role),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _intro() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyMid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyMid.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.navyMid, size: 18,),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Roles are assigned per member. Admins manage roles from the Members screen.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role card ─────────────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role});

  final OrgRole role;

  static const _roleColors = {
    OrgRole.admin: AppColors.navyDark,
    OrgRole.manager: AppColors.gold,
    OrgRole.agent: AppColors.navyMid,
    OrgRole.view: AppColors.textSecondary,
  };

  static const _roleDescriptions = {
    OrgRole.admin: 'Full access. Manages members, teams, invites, and all leads.',
    OrgRole.manager:
        'Manages their team\'s leads and members. Can invite agents.',
    OrgRole.agent: 'Creates and manages their own leads.',
    OrgRole.view: 'Read-only access to leads they\'re assigned to.',
  };

  @override
  Widget build(BuildContext context) {
    final color = _roleColors[role]!;
    final desc = _roleDescriptions[role]!;

    final perms = _buildPermissions(role);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: role == OrgRole.manager
                          ? AppColors.navyDark
                          : AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    desc,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          // Permissions list
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                for (final p in perms)
                  _PermRow(label: p.label, allowed: p.allowed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_Perm> _buildPermissions(OrgRole r) => [
        _Perm('View own leads', OrgPermissionService.canViewOwnLeads(r)),
        _Perm('View team leads', OrgPermissionService.canViewTeamLeads(r)),
        _Perm('View all org leads', OrgPermissionService.canViewAllOrgLeads(r)),
        _Perm('Add leads', OrgPermissionService.canAddLead(r)),
        _Perm('Edit own leads', OrgPermissionService.canEditOwnLead(r)),
        _Perm('Edit team leads', OrgPermissionService.canEditTeamLead(r)),
        _Perm('Delete leads', OrgPermissionService.canDeleteLead(r)),
        _Perm(
          'Reassign leads within team',
          OrgPermissionService.canReassignWithinTeam(r),
        ),
        _Perm(
          'Reassign across teams',
          OrgPermissionService.canReassignAcrossTeams(r),
        ),
        _Perm('Invite members', OrgPermissionService.canInviteRole(r, OrgRole.agent)),
        _Perm('Change member roles', OrgPermissionService.canChangeMemberRole(r)),
        _Perm('Manage teams', OrgPermissionService.canCreateTeam(r)),
        _Perm('View org reports', OrgPermissionService.canViewOrgReports(r)),
        _Perm('Edit org profile', OrgPermissionService.canEditOrgProfile(r)),
      ];
}

class _Perm {
  const _Perm(this.label, this.allowed);
  final String label;
  final bool allowed;
}

class _PermRow extends StatelessWidget {
  const _PermRow({required this.label, required this.allowed});

  final String label;
  final bool allowed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            allowed
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 16,
            color: allowed ? AppColors.success : AppColors.border,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color:
                  allowed ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
