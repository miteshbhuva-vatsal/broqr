import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/services/seed_service.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/entities/organisation.dart';
import 'package:cpapp/features/organisation/domain/services/org_permission_service.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/organisation/presentation/screens/create_org_screen.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_invites_screen.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_members_screen.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_permissions_screen.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_teams_screen.dart';

class OrgScreen extends ConsumerWidget {
  const OrgScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgId = ref.watch(currentOrgIdProvider);
    if (orgId == null) return const _OrgSetupGate();
    return const _OrgProfileBody();
  }
}

// ── Setup gate ────────────────────────────────────────────────────────────────

class _OrgSetupGate extends ConsumerWidget {
  const _OrgSetupGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Organisation'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      floatingActionButton: kDebugMode && user != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_qa',
                  backgroundColor: AppColors.navyDark,
                  tooltip: 'Seed full QA data',
                  onPressed: () async {
                    await SeedService.seedQaData(
                      adminUid: user.uid,
                      adminName: user.name,
                      adminPhotoUrl: user.photoUrl,
                    );
                    ref.read(currentOrgIdProvider.notifier).state =
                        'seed_org_001';
                  },
                  child:
                      const Icon(Icons.dataset_outlined, color: AppColors.gold),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_org',
                  backgroundColor: AppColors.gold,
                  tooltip: 'Seed org data',
                  onPressed: () async {
                    await SeedService.seedOrgData(
                      brokerUid: user.uid,
                      brokerName: user.name,
                      brokerPhotoUrl: user.photoUrl,
                    );
                    ref.read(currentOrgIdProvider.notifier).state =
                        'seed_org_001';
                  },
                  child: const Icon(Icons.science_outlined,
                      color: AppColors.navyDark,),
                ),
              ],
            )
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.business_outlined,
                size: 72,
                color: AppColors.navyMid.withValues(alpha: .4),
              ),
              const SizedBox(height: 24),
              Text(
                'No Organisation',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your own organisation or accept an invitation from a colleague.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateOrgScreen(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create Organisation'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Org profile body ──────────────────────────────────────────────────────────

class _OrgProfileBody extends ConsumerWidget {
  const _OrgProfileBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(watchCurrentOrgProvider);
    final memberAsync = ref.watch(currentOrgMemberProvider);
    final teamsAsync = ref.watch(watchOrgTeamsProvider);
    final crmState = ref.watch(crmProvider);

    return orgAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(child: Text('Error: $e')),
      ),
      data: (org) {
        final member = memberAsync.valueOrNull;
        final role = member?.role ?? OrgRole.view;
        final teamCount = teamsAsync.valueOrNull?.length ?? 0;
        final leadCount = crmState.leads.where((l) => l.orgId == org.id).length;

        return Scaffold(
          backgroundColor: AppColors.offWhite,
          body: CustomScrollView(
            slivers: [
              // ── Sliver app bar with org header ───────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.navyDark,
                foregroundColor: AppColors.white,
                actions: [
                  if (OrgPermissionService.canEditOrgProfile(role))
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit Organisation',
                      onPressed: () {
                        // TODO: org edit screen
                      },
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.navyDark, AppColors.navyMid],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Org avatar
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor:
                                      AppColors.gold.withValues(alpha: .2),
                                  backgroundImage: org.logoUrl != null
                                      ? NetworkImage(org.logoUrl!)
                                      : null,
                                  child: org.logoUrl == null
                                      ? Text(
                                          org.orgName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: AppColors.gold,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        org.orgName,
                                        style:
                                            AppTypography.titleMedium.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.tag,
                                            size: 12,
                                            color:
                                                AppColors.textOnDarkSecondary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            org.orgCode,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color:
                                                  AppColors.textOnDarkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // My role chip
                                _RoleChip(role: role),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Stats row ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      _StatCell(
                        value: org.memberCount.toString(),
                        label: 'Members',
                        icon: Icons.people_outline,
                      ),
                      _Divider(),
                      _StatCell(
                        value: teamCount.toString(),
                        label: 'Teams',
                        icon: Icons.groups_outlined,
                      ),
                      _Divider(),
                      _StatCell(
                        value: leadCount.toString(),
                        label: 'Leads',
                        icon: Icons.leaderboard_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section: Manage ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text(
                    'MANAGE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _NavTile(
                      icon: Icons.people_outline,
                      title: 'Members',
                      subtitle: '${org.memberCount} active member(s)',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OrgMembersScreen(),
                        ),
                      ),
                    ),
                    if (OrgPermissionService.canCreateTeam(role) ||
                        OrgPermissionService.canAddMemberToTeam(role))
                      _NavTile(
                        icon: Icons.groups_outlined,
                        title: 'Teams',
                        subtitle: teamCount > 0
                            ? '$teamCount team(s)'
                            : 'No teams yet',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OrgTeamsScreen(),
                          ),
                        ),
                      ),
                    if (OrgPermissionService.canInviteRole(
                      role,
                      OrgRole.agent,
                    ))
                      _NavTile(
                        icon: Icons.mail_outline_rounded,
                        title: 'Pending Invites',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OrgInvitesScreen(),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),

              // ── Section: Permissions ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text(
                    'PERMISSIONS',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _NavTile(
                      icon: Icons.shield_outlined,
                      title: 'Roles & Permissions',
                      subtitle: 'View what each role can do',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const OrgPermissionsScreen(),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),

              // ── Section: Feed Settings (admin only) ─────────────────────
              if (role == OrgRole.admin) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Text(
                      'FEED SETTINGS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _FeedModeToggle(org: org),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Text(
                      'LEAD SETTINGS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textHint,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _LeadSharingToggle(org: org),
                  ),
                ),
              ],

              // ── Section: CRM access summary ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Text(
                    'YOUR CRM ACCESS',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textHint,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: _CrmAccessCard(role: role),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final OrgRole role;

  static const _colors = {
    OrgRole.admin: AppColors.navyDark,
    OrgRole.manager: AppColors.gold,
    OrgRole.agent: AppColors.navyMid,
    OrgRole.view: AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[role] ?? AppColors.navyMid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        role.label,
        style: AppTypography.labelSmall.copyWith(
          color: role == OrgRole.manager ? AppColors.gold : AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.navyMid, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.navyDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.white,
      child: ListTile(
        leading: Icon(icon, color: AppColors.navyMid),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : null,
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _CrmAccessCard extends StatelessWidget {
  const _CrmAccessCard({required this.role});

  final OrgRole role;

  @override
  Widget build(BuildContext context) {
    final items = <(String, bool)>[
      ('Add leads', OrgPermissionService.canAddLead(role)),
      ('Edit leads', OrgPermissionService.canEditOwnLead(role)),
      ('Delete leads', OrgPermissionService.canDeleteLead(role)),
      ('View team leads', OrgPermissionService.canViewTeamLeads(role)),
      ('View all org leads', OrgPermissionService.canViewAllOrgLeads(role)),
      (
        'Reassign leads',
        OrgPermissionService.canReassignWithinTeam(role),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final (label, allowed) = item;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: allowed
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.border.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: allowed
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allowed
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 13,
                  color: allowed ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: allowed
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Feed mode toggle (admin only) ─────────────────────────────────────────────

class _FeedModeToggle extends ConsumerWidget {
  const _FeedModeToggle({required this.org});
  final Organisation org;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminOnly = org.orgFeedMode == OrgFeedMode.adminOnly;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _FeedModeOption(
            title: 'Show all property feeds',
            subtitle: 'Team members see all listings from every broker',
            icon: Icons.public_rounded,
            selected: !isAdminOnly,
            onTap: () => ref
                .read(orgActionsProvider.notifier)
                .setOrgFeedMode(org.id, OrgFeedMode.all),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _FeedModeOption(
            title: 'Show my listings only',
            subtitle:
                'Team members see only your listings; deal-type filter hidden',
            icon: Icons.lock_outline_rounded,
            selected: isAdminOnly,
            onTap: () => ref
                .read(orgActionsProvider.notifier)
                .setOrgFeedMode(org.id, OrgFeedMode.adminOnly),
          ),
        ],
      ),
    );
  }
}

// ── Lead sharing toggle (admin only) ──────────────────────────────────────────

class _LeadSharingToggle extends ConsumerWidget {
  const _LeadSharingToggle({required this.org});
  final Organisation org;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShared = org.teamLeadsShared;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _LeadSharingOption(
            title: 'Show leads across teams',
            subtitle: 'All org members can see every lead in the organisation',
            icon: Icons.visibility_rounded,
            selected: isShared,
            onTap: () => ref
                .read(orgActionsProvider.notifier)
                .setTeamLeadSharing(org.id, shared: true),
          ),
          const Divider(height: 1, indent: 56, color: AppColors.border),
          _LeadSharingOption(
            title: 'Hide leads between teams',
            subtitle:
                'Members see only their own leads and leads assigned to them',
            icon: Icons.visibility_off_rounded,
            selected: !isShared,
            onTap: () => ref
                .read(orgActionsProvider.notifier)
                .setTeamLeadSharing(org.id, shared: false),
          ),
        ],
      ),
    );
  }
}

class _LeadSharingOption extends StatelessWidget {
  const _LeadSharingOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.navyDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.gold,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedModeOption extends StatelessWidget {
  const _FeedModeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.navyDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.gold, size: 20,),
          ],
        ),
      ),
    );
  }
}
