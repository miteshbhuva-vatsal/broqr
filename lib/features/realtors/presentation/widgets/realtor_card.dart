import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/domain/entities/property_type.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';
import 'package:cpapp/shared/widgets/whatsapp_logo.dart';

class RealtorCard extends ConsumerWidget {
  const RealtorCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.currentUserId,
    required this.onChat,
  });

  final AppUser user;
  final VoidCallback onTap;
  final String currentUserId;
  final VoidCallback onChat;

  Future<void> _call() async {
    final mobile = user.mobile;
    if (mobile == null || mobile.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: '+91$mobile');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final mobile = user.mobile;
    if (mobile == null || mobile.isEmpty) return;
    final uri = Uri.parse('https://wa.me/+91$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = _accountTag(user);
    final tagColor = _tagColor(user);
    final canContact = user.isProfilePublic && (user.mobile?.isNotEmpty ?? false);
    final orgName = user.companyName ??
        (user.orgId != null
            ? ref.watch(orgInfoProvider(user.orgId!)).valueOrNull?.orgName
            : null);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: .04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ────────────────────────────────────────────────
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: _Photo(user: user),
                      ),
                    ),
                    if (user.isVerified)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // ── Info ──────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badge row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: tagColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (orgName != null && orgName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.business_rounded,
                              size: 10,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                orgName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 3),

                      // City
                      if (user.city != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              user.city!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.apartment_rounded,
                              size: 11,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${user.listingsCount} listings',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 6),

                      // Deal categories
                      if (user.dealCategories.isNotEmpty)
                        _MiniChipRow(
                          items: user.dealCategories
                              .take(3)
                              .map((k) {
                                try {
                                  final cat = ListingCategory.fromString(k);
                                  return '${cat.emoji} ${cat.label}';
                                } catch (_) {
                                  return k;
                                }
                              })
                              .toList(),
                          color: AppColors.navyDark,
                        ),

                      // Property types
                      if (user.propertyTypes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _MiniChipRow(
                          items: user.propertyTypes
                              .take(3)
                              .map((k) {
                                final pt = PropertyType.fromString(k);
                                return pt != null ? '${pt.emoji} ${pt.label}' : k;
                              })
                              .toList(),
                          color: const Color(0xFF7C3AED),
                        ),
                      ],

                      // Working areas
                      if (user.workingAreas.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              size: 11,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                user.workingAreas.take(3).join(' · '),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Memberships
                      if (user.memberships.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_outlined,
                              size: 11,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                user.memberships.take(2).join(' · '),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ── Action buttons ────────────────────────────────────────────
            if (user.uid != currentUserId) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ActionButton(
                    iconWidget: const Icon(Icons.call_rounded, size: 15, color: AppColors.success),
                    label: 'Call',
                    color: AppColors.success,
                    enabled: canContact,
                    onTap: _call,
                    tooltip: canContact ? null : 'Private profile',
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    iconWidget: const WhatsAppLogo(size: 15),
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    enabled: canContact,
                    onTap: _whatsapp,
                    tooltip: canContact ? null : 'Private profile',
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    iconWidget: const Icon(Icons.message_rounded, size: 15, color: AppColors.gold),
                    label: 'Chat',
                    color: AppColors.gold,
                    enabled: true,
                    onTap: onChat,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _accountTag(AppUser u) {
    if (u.accountType == 'organisation') return 'Organisation';
    if (u.role != null) {
      return switch (u.role!.name) {
        'builder' => 'Builder',
        'investor' => 'Investor',
        _ => 'Broker',
      };
    }
    return 'Broker';
  }

  Color _tagColor(AppUser u) {
    if (u.accountType == 'organisation') return AppColors.gold;
    if (u.role != null) {
      return switch (u.role!.name) {
        'builder' => AppColors.navyMid,
        'investor' => const Color(0xFF7C3AED),
        _ => AppColors.navyDark,
      };
    }
    return AppColors.navyDark;
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconWidget,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
    this.tooltip,
  });

  final Widget iconWidget;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : AppColors.textHint;

    Widget button = Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: effectiveColor.withValues(alpha: .25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              enabled
                  ? iconWidget
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                          AppColors.textHint, BlendMode.srcIn,),
                      child: iconWidget,
                    ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: effectiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null && !enabled) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

// ── Mini chip row ─────────────────────────────────────────────────────────────

class _MiniChipRow extends StatelessWidget {
  const _MiniChipRow({required this.items, required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Photo ─────────────────────────────────────────────────────────────────────

class _Photo extends StatelessWidget {
  const _Photo({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl != null) {
      return CachedNetworkImage(
        imageUrl: user.photoUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 200,
        placeholder: (_, __) => _Initials(user: user),
        errorWidget: (_, __, ___) => _Initials(user: user),
      );
    }
    return _Initials(user: user);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyDark.withValues(alpha: .08),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.navyDark,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
