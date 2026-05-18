import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/l10n/locale_provider.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';
import 'package:cpapp/features/organisation/domain/entities/org_member.dart';
import 'package:cpapp/features/organisation/domain/services/org_permission_service.dart';
import 'package:cpapp/features/organisation/presentation/providers/org_providers.dart';
import 'package:cpapp/features/organisation/presentation/screens/org_permissions_screen.dart';

class ProfileHubScreen extends ConsumerWidget {
  const ProfileHubScreen({super.key});

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(localeProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LanguagePickerSheet(current: current),
    );
  }

  void _openFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FeedFilterSheet(
        feedState: ref.read(feedProvider),
        onApply: ({category, propertyType, clearCategory, clearPropertyType}) {
          ref.read(feedProvider.notifier).applyFilters(
                category: category,
                propertyType: propertyType,
                clearCategory: clearCategory ?? false,
                clearPropertyType: clearPropertyType ?? false,
              );
        },
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
    final emailCtrl = TextEditingController();
    var selectedRole = OrgRole.agent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invite Member',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email address',
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<OrgRole>(
                  value: selectedRole,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: [OrgRole.manager, OrgRole.agent, OrgRole.view]
                      .where((r) =>
                          callerRole == OrgRole.admin ||
                          r == OrgRole.agent ||
                          r == OrgRole.view,)
                      .map((r) => DropdownMenuItem(value: r, child: Text(r.label),))
                      .toList(),
                  onChanged: (r) {
                    if (r != null) setState(() => selectedRole = r);
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final email = emailCtrl.text.trim();
                  if (email.isEmpty) return;
                  Navigator.pop(ctx);
                  final ok = await ref.read(orgActionsProvider.notifier).sendInvite(
                        orgId: orgId,
                        orgName: orgName,
                        email: email,
                        role: selectedRole,
                        invitedByMemberId: callerMemberId,
                      );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to send invite')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Send Invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final unread = ref.watch(
      notificationsProvider.select((s) => s.unreadCount),
    );
    final activeFilterCount = ref.watch(
      feedProvider.select((s) => s.activeFilterCount),
    );

    // ── Org state ───────────────────────────────────────────────────────────
    final orgId = ref.watch(currentOrgIdProvider);
    final currentUid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
    final org = orgId != null ? ref.watch(watchCurrentOrgProvider).valueOrNull : null;
    final callerMember = orgId != null ? ref.watch(currentOrgMemberProvider).valueOrNull : null;
    final isOrgAdmin = org != null && currentUid != null && org.adminUid == currentUid;
    final callerRole = callerMember?.role ?? (isOrgAdmin ? OrgRole.admin : OrgRole.view);
    final callerMemberId = callerMember?.id ??
        (currentUid != null && org != null ? '${currentUid}_${org.id}' : '');
    final canInvite = org != null && OrgPermissionService.canInviteRole(callerRole, OrgRole.agent);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        title: Text(
          l.navProfile,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
          ),
        ),
        actions: [
          if (canInvite)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Invite Member',
              onPressed: () => _showInviteSheet(
                context,
                ref,
                orgId: org.id,
                orgName: org.orgName,
                callerMemberId: callerMemberId,
                callerRole: callerRole,
              ),
            ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick access tiles ──────────────────────────────────────────
            Row(
              children: [
                _ActionTile(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  accentColor: AppColors.navyMid,
                  onTap: () => context.push(Routes.profile),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _ActionTile(
                  icon: Icons.notifications_rounded,
                  label: 'Alerts',
                  accentColor:
                      unread > 0 ? AppColors.error : AppColors.navyMid,
                  badge: unread > 0 ? unread : null,
                  badgeColor: AppColors.error,
                  onTap: () => context.push(Routes.notifications),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _ActionTile(
                  icon: Icons.translate_rounded,
                  label: 'Language',
                  accentColor: AppColors.navyMid,
                  onTap: () => _showLanguagePicker(context, ref),
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _ActionTile(
                  icon: Icons.tune_rounded,
                  label: 'Filter',
                  accentColor: activeFilterCount > 0
                      ? AppColors.gold
                      : AppColors.navyMid,
                  badge: activeFilterCount > 0 ? activeFilterCount : null,
                  badgeColor: AppColors.gold,
                  onTap: () => _openFilterSheet(context, ref),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Organisation section (only when in an org) ──────────────────
            if (org != null) ...[
              Text(
                'ORGANISATION',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark ? AppColors.textOnDarkSecondary : AppColors.textHint,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              if (canInvite)
                _OrgTile(
                  icon: Icons.person_add_outlined,
                  title: 'Invite Member',
                  subtitle: 'Add a broker to ${org.orgName}',
                  accentColor: AppColors.navyMid,
                  isDark: isDark,
                  onTap: () => _showInviteSheet(
                    context,
                    ref,
                    orgId: org.id,
                    orgName: org.orgName,
                    callerMemberId: callerMemberId,
                    callerRole: callerRole,
                  ),
                ),
              if (canInvite) const SizedBox(height: 8),
              _OrgTile(
                icon: Icons.shield_outlined,
                title: 'Roles & Permissions',
                subtitle: 'View what each role can do',
                accentColor: AppColors.navyMid,
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OrgPermissionsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────────

class _OrgTile extends StatelessWidget {
  const _OrgTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.textOnDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.textOnDarkSecondary : AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
    required this.isDark,
    this.badge,
    this.badgeColor = AppColors.error,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isDark;
  final int? badge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge! > 9 ? '9+' : '$badge',
                          style: TextStyle(
                            color: badgeColor == AppColors.gold
                                ? AppColors.navyDark
                                : AppColors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language picker sheet ─────────────────────────────────────────────────────

class _LanguagePickerSheet extends ConsumerWidget {
  const _LanguagePickerSheet({required this.current});
  final Locale current;

  static const _langs = [
    (Locale('en'), 'English', 'EN'),
    (Locale('hi'), 'हिन्दी', 'HI'),
    (Locale('gu'), 'ગુજરાતી', 'GU'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyMid : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).selectLanguage,
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._langs.map((entry) {
            final (loc, name, code) = entry;
            final selected = locale.languageCode == loc.languageCode;
            return GestureDetector(
              onTap: () {
                ref.read(localeProvider.notifier).setLocale(loc);
                Navigator.of(context).pop();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : (isDark ? AppColors.surfaceDark : AppColors.offWhite),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? AppColors.gold : AppColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.gold
                            : (isDark ? AppColors.navyLight : AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          code,
                          style: AppTypography.labelSmall.copyWith(
                            color: selected
                                ? AppColors.navyDark
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: selected
                            ? (isDark ? AppColors.white : AppColors.navyDark)
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
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
          }),
        ],
      ),
    );
  }
}

// ── Feed filter sheet ─────────────────────────────────────────────────────────

class _FeedFilterSheet extends StatefulWidget {
  const _FeedFilterSheet({required this.feedState, required this.onApply});

  final FeedState feedState;
  final void Function({
    ListingCategory? category,
    PropertyType? propertyType,
    bool? clearCategory,
    bool? clearPropertyType,
  }) onApply;

  @override
  State<_FeedFilterSheet> createState() => _FeedFilterSheetState();
}

class _FeedFilterSheetState extends State<_FeedFilterSheet> {
  late ListingCategory? _category;
  late PropertyType? _propertyType;

  @override
  void initState() {
    super.initState();
    _category = widget.feedState.categoryFilter;
    _propertyType = widget.feedState.propertyTypeFilter;
  }

  void _apply() {
    widget.onApply(
      category: _category,
      propertyType: _propertyType,
      clearCategory: _category == null,
      clearPropertyType: _propertyType == null,
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _category = null;
      _propertyType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.navyMid : AppColors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context).filterListings,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? AppColors.white : AppColors.navyDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    AppLocalizations.of(context).reset,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.of(context).dealType.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 88,
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 2.8,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              scrollDirection: Axis.vertical,
              physics: const NeverScrollableScrollPhysics(),
              children: ListingCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = sel ? null : cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? cat.color.withValues(alpha: 0.18)
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.offWhite),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: sel ? cat.color : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${cat.emoji} ${cat.localizedLabel(Localizations.localeOf(context).languageCode)}',
                        style: AppTypography.labelSmall.copyWith(
                          color: sel ? cat.color : AppColors.textSecondary,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppLocalizations.of(context).propertyType.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: PropertyType.values.map((pt) {
                final sel = _propertyType == pt;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _propertyType = sel ? null : pt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.navyDark.withValues(alpha: 0.1)
                          : (isDark
                              ? AppColors.surfaceDark
                              : AppColors.offWhite),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.navyDark : AppColors.border,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${pt.emoji} ${pt.label}',
                      style: AppTypography.labelSmall.copyWith(
                        color: sel
                            ? AppColors.navyDark
                            : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  AppLocalizations.of(context).applyFilters,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.navyDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
