import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/organisation/domain/entities/org_invite.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/services/org_permission_service.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';

class OrgMembersScreen extends ConsumerWidget {
  const OrgMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(watchOrgMembersProvider);
    final callerAsync = ref.watch(currentOrgMemberProvider);
    final orgAsync = ref.watch(watchCurrentOrgProvider);
    final currentUid = ref.watch(authStateChangesProvider).valueOrNull?.uid;

    // Resolve role: use member record if loaded, fallback to admin check via org doc.
    final callerMember = callerAsync.valueOrNull;
    final org = orgAsync.valueOrNull;
    final isOrgAdmin = org != null && currentUid != null && org.adminUid == currentUid;
    final callerRole = callerMember?.role ?? (isOrgAdmin ? OrgRole.admin : OrgRole.view);
    final canInvite = OrgPermissionService.canInviteRole(callerRole, OrgRole.agent);

    // Synthesise a minimal member id for the invite call when the record is still loading.
    final callerMemberId = callerMember?.id ??
        (currentUid != null && org != null ? '${currentUid}_${org.id}' : '');

    void openInviteSheet() {
      if (org == null) return;
      _showInviteSheet(context, ref,
          orgId: org.id,
          orgName: org.orgName,
          callerMemberId: callerMemberId,
          callerRole: callerRole,);
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: AppColors.navyDark,
        foregroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (canInvite)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Invite Member',
              onPressed: openInviteSheet,
            ),
        ],
      ),
      floatingActionButton: canInvite
          ? FloatingActionButton.extended(
              heroTag: 'members-invite-fab',
              backgroundColor: AppColors.navyMid,
              icon: const Icon(Icons.person_add_outlined, color: AppColors.white),
              label: const Text('Invite Member',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600,),),
              onPressed: openInviteSheet,
            )
          : null,
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) => members.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    const Text('No members yet',
                        style: TextStyle(color: AppColors.textSecondary),),
                    if (canInvite) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: openInviteSheet,
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Invite first member'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navyMid,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                itemBuilder: (context, i) => _MemberTile(
                  member: members[i],
                  callerRole: callerRole,
                  callerId: callerMember?.id,
                ),
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

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.callerRole,
    required this.callerId,
  });

  final OrgMember member;
  final OrgRole callerRole;
  final String? callerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelf = member.id == callerId;
    final canEdit = OrgPermissionService.canChangeMemberRole(callerRole) &&
        !isSelf &&
        member.role != OrgRole.admin;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: AppColors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(member.role).withValues(alpha: .15),
          backgroundImage: member.brokerPhotoUrl != null
              ? NetworkImage(member.brokerPhotoUrl!)
              : null,
          child: member.brokerPhotoUrl == null
              ? Text(
                  member.brokerName.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: _roleColor(member.role),
                      fontWeight: FontWeight.bold,),
                )
              : null,
        ),
        title: Text(
          member.brokerName + (isSelf ? ' (You)' : ''),
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600,),
        ),
        subtitle: Text(
          member.role.label,
          style: TextStyle(color: _roleColor(member.role), fontSize: 12),
        ),
        trailing: canEdit
            ? PopupMenuButton<String>(
                onSelected: (action) => _handleAction(context, ref, action),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'promote',
                    child: Text('Change Role'),
                  ),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Text('Remove', style: TextStyle(color: Colors.red)),
                  ),
                ],
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action,) async {
    if (action == 'deactivate') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Remove Member'),
          content: Text(
              'Remove ${member.brokerName} from the organisation? They will lose access immediately.',),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Remove', style: TextStyle(color: Colors.red)),),
          ],
        ),
      );
      if (confirm != true || !context.mounted) return;
      final ok = await ref
          .read(orgActionsProvider.notifier)
          .deactivateMember(member.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '${member.brokerName} removed. Their access has been revoked.'
              : 'Failed to remove member. Please try again.',),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (action == 'promote') {
      _showRolePicker(context, ref);
    }
  }

  void _showRolePicker(BuildContext context, WidgetRef ref) {
    // Admin can assign any non-admin role; manager can only assign agent/view.
    final assignable = [OrgRole.manager, OrgRole.agent, OrgRole.view]
        .where((r) => OrgPermissionService.canInviteRole(callerRole, r))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Change role — ${member.brokerName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (final role in assignable)
              ListTile(
                title: Text(role.label),
                leading: Icon(Icons.circle, size: 12, color: _roleColor(role)),
                trailing: member.role == role
                    ? const Icon(Icons.check, size: 18)
                    : null,
                selected: member.role == role,
                selectedTileColor: AppColors.offWhite,
                onTap: member.role == role
                    ? null
                    : () {
                        Navigator.pop(context);
                        ref.read(orgActionsProvider.notifier).updateMemberRole(
                              memberId: member.id,
                              role: role,
                            );
                      },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _roleColor(OrgRole role) => switch (role) {
        OrgRole.admin => AppColors.navyDark,
        OrgRole.manager => AppColors.gold,
        OrgRole.agent => AppColors.navyMid,
        OrgRole.view => AppColors.textSecondary,
      };
}

// ── Shared invite sheet (used by MembersScreen, InvitesScreen, ProfileScreen) ─

void showOrgInviteSheet(
  BuildContext context,
  WidgetRef ref, {
  required String orgId,
  required String orgName,
  required String callerMemberId,
  required OrgRole callerRole,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _OrgInviteSheetBody(
      orgId: orgId,
      orgName: orgName,
      callerMemberId: callerMemberId,
      callerRole: callerRole,
    ),
  );
}

class _OrgInviteSheetBody extends ConsumerStatefulWidget {
  const _OrgInviteSheetBody({
    required this.orgId,
    required this.orgName,
    required this.callerMemberId,
    required this.callerRole,
  });

  final String orgId;
  final String orgName;
  final String callerMemberId;
  final OrgRole callerRole;

  @override
  ConsumerState<_OrgInviteSheetBody> createState() => _OrgInviteSheetBodyState();
}

class _OrgInviteSheetBodyState extends ConsumerState<_OrgInviteSheetBody> {
  final _inputCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();
  final _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ),);

  OrgRole _selectedRole = OrgRole.agent;
  bool _useMobile  = false;
  bool _otpSent    = false;  // mobile only: OTP has been dispatched
  bool _loading    = false;
  String? _error;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  static String? _extractError(dynamic data) {
    if (data is Map) return data['error']?.toString();
    return null;
  }

  // ── Mobile: step 1 – send OTP ─────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final phone = _inputCtrl.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.post<dynamic>('/api/otp/send',
          data: {'mobile': phone},);
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        if (!mounted) return;
        setState(() { _loading = false; _otpSent = true; });
      } else {
        _setError(_extractError(data) ?? 'Failed to send OTP.');
      }
    } on DioException catch (e) {
      _setError(_extractError(e.response?.data) ?? 'Failed to send OTP.');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  // ── Mobile: step 2 – verify OTP then create invite ────────────────────────

  Future<void> _verifyAndInvite() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.post<dynamic>('/api/otp/verify',
          data: {'mobile': _inputCtrl.text.trim(), 'otp': otp},);
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        await _createInvite(mobileVerified: true);
      } else {
        _setError(_extractError(data) ?? 'Incorrect OTP. Please try again.');
      }
    } on DioException catch (e) {
      _setError(_extractError(e.response?.data) ?? 'Incorrect OTP. Please try again.');
    } catch (_) {
      _setError('Something went wrong. Please try again.');
    }
  }

  // ── Email: send invite directly ───────────────────────────────────────────

  Future<void> _sendEmailInvite() async {
    final email = _inputCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    await _createInvite(mobileVerified: false);
  }

  // ── Shared invite creation ────────────────────────────────────────────────

  Future<void> _createInvite({required bool mobileVerified}) async {
    final input = _inputCtrl.text.trim();
    final ok = await ref.read(orgActionsProvider.notifier).sendInvite(
          orgId: widget.orgId,
          orgName: widget.orgName,
          email: _useMobile ? '' : input,
          mobile: _useMobile ? input : null,
          role: _selectedRole,
          invitedByMemberId: widget.callerMemberId,
          mobileVerified: mobileVerified,
        );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _loading = false;
        _inputCtrl.clear();
        _otpCtrl.clear();
        _otpSent = false;
        _error = null;
      });
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ),
              const SizedBox(height: 12),
              const Text(
                'Invite Sent!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                mobileVerified
                    ? 'Mobile number verified. ${_useMobile ? "+91 $input" : input} will be auto-joined on login.'
                    : '${_useMobile ? "+91 $input" : input} has been invited to ${widget.orgName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navyMid,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } else {
      _setError('Failed to send invite. Please try again.');
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() { _loading = false; _error = msg; });
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync = ref.watch(allOrgInvitesProvider);
    final membersAsync = ref.watch(watchOrgMembersProvider);
    final members = membersAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Invite Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email / Mobile toggle (disabled after OTP is sent)
          Row(
            children: [
              _InviteToggleChip(
                label: 'Email',
                selected: !_useMobile,
                onTap: _otpSent ? null : () => setState(() {
                  _useMobile = false;
                  _inputCtrl.clear();
                  _otpCtrl.clear();
                  _otpSent = false;
                  _error = null;
                }),
              ),
              const SizedBox(width: 8),
              _InviteToggleChip(
                label: 'Mobile',
                selected: _useMobile,
                onTap: _otpSent ? null : () => setState(() {
                  _useMobile = true;
                  _inputCtrl.clear();
                  _otpCtrl.clear();
                  _error = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Mobile number field (always visible) ──────────────────────
          TextField(
            controller: _inputCtrl,
            autofocus: true,
            readOnly: _otpSent,
            keyboardType:
                _useMobile ? TextInputType.phone : TextInputType.emailAddress,
            maxLength: _useMobile ? 10 : null,
            inputFormatters: _useMobile
                ? [FilteringTextInputFormatter.digitsOnly]
                : [],
            decoration: InputDecoration(
              labelText: _useMobile ? 'Mobile number' : 'Email address',
              prefixText: _useMobile ? '+91  ' : null,
              prefixIcon: Icon(
                _useMobile ? Icons.phone_outlined : Icons.email_outlined,
              ),
              counterText: '',
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _otpSent
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => setState(() {
                        _otpSent = false;
                        _otpCtrl.clear();
                        _error = null;
                      }),
                    )
                  : null,
            ),
          ),

          // ── OTP field (mobile step 2) ──────────────────────────────────
          if (_useMobile && _otpSent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _otpCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(letterSpacing: 8, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'OTP sent to +91 ${_inputCtrl.text.trim()}',
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: const TextStyle(letterSpacing: 8),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          // ── Role picker (shown before OTP step) ───────────────────────
          if (!_otpSent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<OrgRole>(
                value: _selectedRole,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                items: [OrgRole.manager, OrgRole.agent, OrgRole.view]
                    .where((r) =>
                        widget.callerRole == OrgRole.admin ||
                        r == OrgRole.agent ||
                        r == OrgRole.view,)
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label),))
                    .toList(),
                onChanged: (r) {
                  if (r != null) setState(() => _selectedRole = r);
                },
              ),
            ),
          ],

          // ── Error ──────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // ── Primary action button ──────────────────────────────────────
          FilledButton(
            onPressed: _loading
                ? null
                : _useMobile
                    ? (_otpSent ? _verifyAndInvite : _sendOtp)
                    : _sendEmailInvite,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white,),
                  )
                : Text(_useMobile
                    ? (_otpSent ? 'Verify & Invite' : 'Send OTP')
                    : 'Send Invite',),
          ),

          // ── Invite + member lists ─────────────────────────────────────
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),

          invitesAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (invites) {
              final pending  = invites.where((i) => i.isPending).toList();
              final accepted = invites.where(
                (i) => i.status == InviteStatus.accepted,
              ).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Joined members ──────────────────────────────────
                  if (accepted.isNotEmpty) ...[
                    _SectionHeader(
                      label: 'Active Members',
                      count: accepted.length,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    ...accepted.map((inv) {
                      // Cross-reference with real member record by mobile.
                      final member = members.firstWhere(
                        (m) => m.brokerMobile == inv.mobile,
                        orElse: () => OrgMember(
                          id: '',
                          orgId: inv.orgId,
                          brokerUid: '',
                          brokerName: inv.displayIdentifier,
                          role: inv.role,
                          isActive: true,
                          invitedBy: inv.invitedBy,
                          invitedAt: inv.createdAt,
                          joinedAt: inv.createdAt,
                          createdAt: inv.createdAt,
                        ),
                      );
                      return _JoinedMemberRow(member: member, invite: inv);
                    }),
                    const SizedBox(height: 16),
                  ],

                  // ── Pending invites ─────────────────────────────────
                  _SectionHeader(
                    label: 'Pending Invites',
                    count: pending.length,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  if (pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No pending invites',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13,),
                        ),
                      ),
                    )
                  else
                    ...pending.map((inv) => _InviteRow(invite: inv)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InviteRow extends ConsumerWidget {
  const _InviteRow({required this.invite});

  final OrgInvite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color statusColor;
    final String statusLabel;
    switch (invite.status) {
      case InviteStatus.pending:
        statusColor = Colors.orange;
        statusLabel = 'Pending';
      case InviteStatus.accepted:
        statusColor = Colors.green;
        statusLabel = 'Accepted';
      case InviteStatus.revoked:
        statusColor = AppColors.textSecondary;
        statusLabel = 'Revoked';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            invite.isMobileInvite ? Icons.phone_outlined : Icons.email_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.displayIdentifier,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  invite.role.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          if (invite.isPending) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  ref.read(orgActionsProvider.notifier).revokeInvite(invite.id),
              child: const Icon(Icons.close, size: 16, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteToggleChip extends StatelessWidget {
  const _InviteToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Section header for invite/member lists ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Joined member row (accepted invite cross-referenced with member record) ───

class _JoinedMemberRow extends StatelessWidget {
  const _JoinedMemberRow({required this.member, required this.invite});

  final OrgMember member;
  final OrgInvite invite;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = member.brokerPhotoUrl != null;
    final initial = member.brokerName.isNotEmpty
        ? member.brokerName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.withValues(alpha: 0.15),
            backgroundImage: hasPhoto ? NetworkImage(member.brokerPhotoUrl!) : null,
            child: hasPhoto
                ? null
                : Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.brokerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${invite.role.label}  ·  ${invite.displayIdentifier}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
