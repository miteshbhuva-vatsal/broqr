import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/services/deep_link_service.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';
import 'package:cpapp/features/realtors/presentation/providers/realtors_providers.dart';
import 'package:cpapp/shared/widgets/whatsapp_logo.dart';

class RealtorProfileScreen extends ConsumerWidget {
  const RealtorProfileScreen({super.key, required this.realtorId});

  final String realtorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(realtorProfileProvider(realtorId));

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Realtor not found.')),
          );
        }
        return _ProfileView(user: user);
      },
    );
  }
}

// ── Main profile view ─────────────────────────────────────────────────────────

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(
        orgCombinedListingsProvider((uid: user.uid, orgId: user.orgId,)),);
    final orgInfoAsync =
        user.orgId != null && user.companyName == null
            ? ref.watch(orgInfoProvider(user.orgId!))
            : null;
    final orgDisplayName =
        user.companyName ?? orgInfoAsync?.valueOrNull?.orgName;
    final l = AppLocalizations.of(context);
    final yearsExp =
        DateTime.now().difference(user.createdAt).inDays ~/ 365;
    final currentUid =
        ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.navyDark,
            foregroundColor: AppColors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.link_rounded),
                tooltip: l.copyProfileLink,
                onPressed: () {
                  final me = ref.read(authStateChangesProvider).valueOrNull;
                  final refCode = me?.effectiveReferralCode ??
                      user.uid.substring(0, 8).toUpperCase();
                  final link =
                      DeepLinkService.brokerUri(user.uid, refCode).toString();
                  Clipboard.setData(ClipboardData(text: link));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l.profileLinkCopied),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: l.shareProfile,
                onPressed: () {
                  final me = ref.read(authStateChangesProvider).valueOrNull;
                  final refCode = me?.effectiveReferralCode ??
                      user.uid.substring(0, 8).toUpperCase();
                  final text = DeepLinkService.brokerShareText(
                    brokerName: user.name,
                    city: user.city,
                    brokerId: user.uid,
                    referralCode: refCode,
                  );
                  Share.share(text, subject: '${user.name} on CPApp');
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.navyDark, Color(0xFF1A2E4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Avatar(user: user),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user.name,
                                    style: AppTypography.titleLarge.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (user.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: Color(0xFF22C55E),
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                            if (orgDisplayName != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.business_rounded,
                                    size: 11,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      orgDisplayName,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.white
                                            .withValues(alpha: .85),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (user.city != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white70,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    user.city!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
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
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats ──────────────────────────────────────────────
                  _StatsRow(
                    listingsCount: listingsAsync.maybeWhen(
                      data: (ls) => ls.length,
                      orElse: () => user.listingsCount,
                    ),
                    yearsExp: yearsExp,
                  ),
                  const SizedBox(height: 16),

                  // ── Contact actions (hidden when viewing own profile) ───
                  if (user.uid != currentUid)
                    _ContactButtons(user: user, currentUid: currentUid),
                  if (user.uid != currentUid) const SizedBox(height: 16),

                  // ── Chips (city, RERA, GST) ────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (user.reraNumber != null)
                        _InfoChip(
                          icon: Icons.verified_user_outlined,
                          label: 'RERA: ${user.reraNumber}',
                          color: AppColors.success,
                        ),
                      if (user.accountType == 'organisation' &&
                          user.gstNo != null)
                        _InfoChip(
                          icon: Icons.receipt_long_outlined,
                          label: 'GST: ${user.gstNo}',
                          color: AppColors.navyMid,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Categories from listings ───────────────────────────
                  listingsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (listings) {
                      if (listings.isEmpty) return const SizedBox.shrink();
                      final cats =
                          listings.map((l) => l.category).toSet().toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(l.specialisesIn),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cats
                                .map((c) => _CategoryChip(category: c))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // ── Listings ───────────────────────────────────────────
                  Row(
                    children: [
                      _SectionLabel(l.listings),
                      const Spacer(),
                      listingsAsync.maybeWhen(
                        data: (ls) => Text(
                          '${ls.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  listingsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    error: (_, __) => Text(
                      l.couldNotLoadListings,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    data: (listings) {
                      if (listings.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              l.noListingsPosted,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: listings
                            .map((li) => _ListingTile(listing: li))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Contact buttons (Call / WhatsApp / Chat) ──────────────────────────────────

class _ContactButtons extends StatelessWidget {
  const _ContactButtons({required this.user, required this.currentUid});

  final AppUser user;
  final String currentUid;

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
  Widget build(BuildContext context) {
    final canContact =
        user.isProfilePublic && (user.mobile?.isNotEmpty ?? false);

    return Row(
      children: [
        _ProfileActionButton(
          iconWidget: const Icon(Icons.call_rounded, size: 16, color: AppColors.success),
          label: 'Call',
          color: AppColors.success,
          enabled: canContact,
          onTap: _call,
          tooltip: canContact ? null : 'Private profile',
        ),
        const SizedBox(width: 10),
        _ProfileActionButton(
          iconWidget: const WhatsAppLogo(size: 16),
          label: 'WhatsApp',
          color: const Color(0xFF25D366),
          enabled: canContact,
          onTap: _whatsapp,
          tooltip: canContact ? null : 'Private profile',
        ),
        const SizedBox(width: 10),
        _ProfileActionButton(
          iconWidget: const Icon(Icons.message_rounded, size: 16, color: AppColors.gold),
          label: 'Chat',
          color: AppColors.gold,
          enabled: true,
          onTap: () {
            final ids = [currentUid, user.uid]..sort();
            final chatId = ids.join('_');
            context.push(
              Routes.chatDetail.replaceFirst(':chatId', chatId),
              extra: {
                'otherName': user.name,
                'otherPhoto': user.photoUrl,
                'otherUid': user.uid,
              },
            );
          },
        ),
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
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
    Widget btn = Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: effectiveColor.withValues(alpha: .30)),
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
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
      btn = Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          backgroundImage: user.photoUrl != null
              ? CachedNetworkImageProvider(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                )
              : null,
        ),
        if (user.isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                size: 14,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.listingsCount, required this.yearsExp});
  final int listingsCount;
  final int yearsExp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final divider = Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyDark.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: listingsCount.toString(),
              label: l.listings,
            ),
          ),
          divider,
          Expanded(
            child: _StatCell(
              value: yearsExp > 0 ? '$yearsExp+' : '<1',
              label: 'Yrs on CPApp',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navyDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.navyDark,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final ListingCategory category;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: category.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            category.localizedLabel(lang),
            style: TextStyle(
              color: category.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact listing tile ──────────────────────────────────────────────────────

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onTap: () => context.push(
        Routes.listingDetail.replaceFirst(':listingId', listing.id),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: .04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 72,
                height: 72,
                child: CachedNetworkImage(
                  imageUrl: listing.heroImageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                  placeholder: (_, __) =>
                      Container(color: AppColors.offWhite),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.offWhite,
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: listing.category.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${listing.category.emoji} ${listing.category.localizedLabel(lang)}',
                      style: TextStyle(
                        color: listing.category.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${listing.location}, ${listing.city}',
                    style: const TextStyle(
                      color: AppColors.navyDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        listing.priceLabel,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (listing.propertyType != null) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          listing.propertyType!.label,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
