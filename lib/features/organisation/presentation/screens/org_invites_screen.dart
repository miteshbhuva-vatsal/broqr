import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/features/organisation/domain/entities/org_invite.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_members_screen.dart';

class OrgInvitesScreen extends ConsumerWidget {
  const OrgInvitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(pendingInvitesProvider);
    final orgAsync = ref.watch(watchCurrentOrgProvider);
    final callerAsync = ref.watch(currentOrgMemberProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Pending Invites'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () {
              final org = orgAsync.valueOrNull;
              final caller = callerAsync.valueOrNull;
              if (org == null || caller == null) return;
              _showInviteSheet(context, ref,
                  orgId: org.id,
                  orgName: org.orgName,
                  callerMemberId: caller.id,
                  callerRole: caller.role,);
            },
          ),
        ],
      ),
      body: invitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invites) => invites.isEmpty
            ? const Center(
                child: Text('No pending invites',
                    style: TextStyle(color: AppColors.textSecondary),),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: invites.length,
                itemBuilder: (context, i) => _InviteTile(invite: invites[i]),
              ),
      ),
    );
  }

  void _showInviteSheet(
    BuildContext context,
    WidgetRef ref, {
    required String orgId,
    required String orgName,
    required String callerMemberId,
    required OrgRole callerRole,
  }) {
    showOrgInviteSheet(
      context,
      ref,
      orgId: orgId,
      orgName: orgName,
      callerMemberId: callerMemberId,
      callerRole: callerRole,
    );
  }
}

class _InviteTile extends ConsumerWidget {
  const _InviteTile({required this.invite});

  final OrgInvite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFF7ED),
          child: Icon(
            invite.isMobileInvite ? Icons.phone_outlined : Icons.mail_outline,
            color: AppColors.gold,
          ),
        ),
        title: Text(
          invite.displayIdentifier,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600,),
        ),
        subtitle: Text(
          '${invite.role.label} · expires ${_fmtDate(invite.expiresAt)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: () async {
            await ref.read(orgActionsProvider.notifier).revokeInvite(invite.id);
          },
          child: const Text('Revoke', style: TextStyle(color: AppColors.error)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
