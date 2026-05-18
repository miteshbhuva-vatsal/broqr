import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/entities/org_team.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';

class OrgTeamsScreen extends ConsumerWidget {
  const OrgTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(watchOrgTeamsProvider);
    final orgId = ref.watch(currentOrgIdProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Teams'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create team',
            onPressed: orgId == null
                ? null
                : () => _showCreateTeamSheet(context, ref, orgId),
          ),
        ],
      ),
      body: teamsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (teams) => teams.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: AppColors.textHint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No teams yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap + to create your first team',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: teams.length,
                itemBuilder: (context, i) => _TeamCard(
                  team: teams[i],
                  orgId: orgId ?? '',
                ),
              ),
      ),
    );
  }

  void _showCreateTeamSheet(
    BuildContext context,
    WidgetRef ref,
    String orgId,
  ) {
    final ctrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'New Team',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Team name',
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                await ref
                    .read(orgActionsProvider.notifier)
                    .createTeam(orgId: orgId, teamName: name);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Team card with expandable member list ─────────────────────────────────────

class _TeamCard extends ConsumerStatefulWidget {
  const _TeamCard({required this.team, required this.orgId});

  final OrgTeam team;
  final String orgId;

  @override
  ConsumerState<_TeamCard> createState() => _TeamCardState();
}

class _TeamCardState extends ConsumerState<_TeamCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final memberIdsAsync =
        ref.watch(watchTeamMemberIdsProvider(widget.team.id));
    final allMembersAsync = ref.watch(watchOrgMembersProvider);

    final memberIds = memberIdsAsync.valueOrNull ?? [];
    final allMembers = allMembersAsync.valueOrNull ?? [];

    // Active members already in this team
    final teamMembers = allMembers
        .where((m) => m.isActive && memberIds.contains(m.id))
        .toList();

    // Active members NOT yet in this team (for the add picker)
    final availableMembers = allMembers
        .where((m) => m.isActive && !memberIds.contains(m.id))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      color: AppColors.white,
      child: Column(
        children: [
          // ── Header row ────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(14),
              bottom: _expanded ? Radius.zero : const Radius.circular(14),
            ),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFEEF2FF),
                    child: Icon(
                      Icons.groups,
                      color: AppColors.navyMid,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.team.teamName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${teamMembers.length} member(s)',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondary,
                    ),
                    onSelected: (action) async {
                      if (action == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete Team'),
                            content: Text(
                              'Delete "${widget.team.teamName}"? Members are not removed from the org.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(orgActionsProvider.notifier)
                              .deleteTeam(widget.team.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Team',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded member list ──────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            if (teamMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No members in this team yet.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              )
            else
              ...teamMembers.map(
                (m) => _TeamMemberRow(
                  member: m,
                  teamId: widget.team.id,
                ),
              ),
            const Divider(height: 1, color: AppColors.border),
            // ── Add member button ──────────────────────────────────────
            InkWell(
              onTap: availableMembers.isEmpty
                  ? null
                  : () => _showAddMemberSheet(
                        context,
                        ref,
                        availableMembers,
                      ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 18,
                      color: availableMembers.isEmpty
                          ? AppColors.textHint
                          : AppColors.navyMid,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      availableMembers.isEmpty
                          ? 'All active members are in this team'
                          : 'Add member to team',
                      style: AppTypography.labelMedium.copyWith(
                        color: availableMembers.isEmpty
                            ? AppColors.textHint
                            : AppColors.navyMid,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddMemberSheet(
    BuildContext context,
    WidgetRef ref,
    List<OrgMember> available,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddMemberSheet(
        teamId: widget.team.id,
        teamName: widget.team.teamName,
        availableMembers: available,
      ),
    );
  }
}

// ── Member row inside an expanded team ────────────────────────────────────────

class _TeamMemberRow extends ConsumerWidget {
  const _TeamMemberRow({required this.member, required this.teamId});

  final OrgMember member;
  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.navyMid.withValues(alpha: 0.1),
        backgroundImage: member.brokerPhotoUrl != null
            ? NetworkImage(member.brokerPhotoUrl!)
            : null,
        child: member.brokerPhotoUrl == null
            ? Text(
                member.brokerName.isNotEmpty
                    ? member.brokerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.navyMid,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        member.brokerName,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        member.role.label,
        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.remove_circle_outline,
          color: Colors.red,
          size: 20,
        ),
        tooltip: 'Remove from team',
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Remove Member'),
              content: Text('Remove ${member.brokerName} from this team?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(orgActionsProvider.notifier).removeMemberFromTeam(
                  teamId: teamId,
                  memberId: member.id,
                );
          }
        },
      ),
    );
  }
}

// ── Add member bottom sheet ───────────────────────────────────────────────────

class _AddMemberSheet extends ConsumerStatefulWidget {
  const _AddMemberSheet({
    required this.teamId,
    required this.teamName,
    required this.availableMembers,
  });

  final String teamId;
  final String teamName;
  final List<OrgMember> availableMembers;

  @override
  ConsumerState<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<_AddMemberSheet> {
  String? _selectedMemberId;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add to ${widget.teamName}',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.navyDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select an active org member to add',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            RadioGroup<String>(
              groupValue: _selectedMemberId,
              onChanged: (v) => setState(() => _selectedMemberId = v),
              child: Column(
                children: widget.availableMembers.map(
                  (m) => InkWell(
                    onTap: () => setState(() => _selectedMemberId = m.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: m.id,
                            activeColor: AppColors.navyMid,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppColors.navyMid.withValues(alpha: 0.1),
                            child: Text(
                              m.brokerName.isNotEmpty
                                  ? m.brokerName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.navyMid,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.brokerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  m.role.label,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedMemberId == null || _saving) ? null : _add,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor:
                      AppColors.navyMid.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Add to Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add() async {
    if (_selectedMemberId == null) return;
    setState(() => _saving = true);
    await ref.read(orgActionsProvider.notifier).addMemberToTeam(
          teamId: widget.teamId,
          memberId: _selectedMemberId!,
        );
    if (mounted) Navigator.pop(context);
  }
}
