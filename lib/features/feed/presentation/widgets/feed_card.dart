import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';
import 'package:cpapp/features/broker_network/presentation/providers/network_providers.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/crm/presentation/widgets/listing_leads_sheet.dart';
import 'package:cpapp/core/services/deep_link_service.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/shared/widgets/phone_otp_sheet.dart';

// ignore: unused_import — kept for InquireSheet used in listing_detail_screen
// import 'package:cpapp/features/feed/presentation/widgets/inquire_sheet.dart';

class FeedCard extends ConsumerStatefulWidget {
  const FeedCard({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<FeedCard> {
  Timer? _viewTimer;
  bool _phoneRevealed = false;

  @override
  void initState() {
    super.initState();
    // Only count a view after the card has been visible for 1.5 s.
    // Cards scrolled past quickly are never counted — cuts write volume ~70%.
    _viewTimer = Timer(const Duration(milliseconds: 1500), () {
      ref.read(feedProvider.notifier).trackView(widget.listing);
    });
  }

  @override
  void dispose() {
    _viewTimer?.cancel();
    super.dispose();
  }

  void _share() {
    final l = widget.listing;
    final user = ref.read(authStateChangesProvider).valueOrNull;
    final refCode = user?.effectiveReferralCode ?? l.brokerUid.substring(0, 8).toUpperCase();
    final text = DeepLinkService.listingShareText(
      emoji: l.category.emoji,
      category: l.category.label,
      location: l.location,
      city: l.city,
      price: l.priceLabel,
      area: l.areaLabel,
      brokerName: l.brokerName,
      listingId: l.id,
      referralCode: refCode,
    );
    Share.share(text, subject: '${l.category.label} on CPApp');
  }

  void _openBrokerProfile() {
    final listing = widget.listing;
    final myUid =
        ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    if (listing.brokerUid == myUid) {
      context.push(Routes.profile);
    } else {
      context.push(
        Routes.brokerProfile.replaceFirst(':brokerId', listing.brokerUid),
      );
    }
  }

  Future<void> _onContactTap() async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    final isVerified = ref.read(isPhoneVerifiedProvider);
    if (isVerified) {
      await _doContact();
    } else {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PhoneOtpSheet(
          initialPhone: user.mobile,
          onVerified: () => Future.microtask(_doContact),
        ),
      );
    }
  }

  Future<void> _doContact() async {
    final listing = widget.listing;
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    // Auto-add a lead in the broker's CRM representing this inquiry
    try {
      await FirebaseFirestore.instance.collection('leads').add({
        'ownerUid': listing.brokerUid,
        'clientName': user.name,
        'clientPhone': user.mobile ?? '',
        'stage': 'newLead',
        'priority': 'medium',
        'linkedListingId': listing.id,
        'linkedListingCity': listing.city,
        'linkedListingPrice': listing.priceLabel,
        'notes': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Don't block phone reveal if lead creation fails
    }

    // Notify the listing owner (fire-and-forget; skip if user is the owner)
    if (user.uid != listing.brokerUid) {
      unawaited(
        ref.read(notificationRemoteDataSourceProvider).createNotification(
          recipientUid: listing.brokerUid,
          type: NotificationType.listingInquiry,
          title: 'New inquiry on your listing',
          body: '${user.name} is interested in your ${listing.category.label} in ${listing.city}',
          actorUid: user.uid,
          targetId: listing.id,
        ),
      );
    }

    if (mounted) {
      setState(() => _phoneRevealed = true);
      if (listing.brokerPhone == null || listing.brokerPhone!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Broker hasn't added a contact number yet"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final listing = widget.listing;
    // select() means this card only rebuilds when ITS liked state changes,
    // not when any other listing in the feed changes.
    final isLiked = ref.watch(
      feedProvider.select((s) => s.isLiked(listing.id)),
    );

    return GestureDetector(
      onTap: () => context.push(
        Routes.listingDetail.replaceFirst(':listingId', listing.id),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image with overlays ────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: listing.heroImageUrl,
                      fit: BoxFit.cover,
                      // Decode at display width — saves ~60% memory vs full res
                      memCacheWidth: 800,
                      placeholder: (_, __) => Container(
                        color: isDark
                            ? AppColors.navyMid
                            : AppColors.surfaceLight,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.surfaceLight,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textHint,
                          size: 40,
                        ),
                      ),
                    ),
                    // Gradient overlay — light top, clear mid, heavy navy bottom
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.45, 1.0],
                          colors: [
                            Color(0x33000000),
                            Colors.transparent,
                            Color(0xF20A1628),
                          ],
                        ),
                      ),
                    ),
                    // Category badge — top-left: dark navy pill with gold border
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _CategoryBadge(listing: listing),
                    ),
                    // Area badge — top-right: frosted pill with area label
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // CPApp watermark — tiny gold text, top-far-right
                          const Text(
                            'CPApp',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (listing.area > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x99000000),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                listing.areaLabel,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Bottom overlay: price + location left, property type right
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Left: title (optional) + price + location
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (listing.title != null &&
                                      listing.title!.isNotEmpty) ...[
                                    Text(
                                      listing.title!.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  _DualPrice(listing: listing, dealFontSize: 26),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.white,
                                        size: 12,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          '${listing.location}, ${listing.city}',
                                          style: const TextStyle(
                                            color: Color(0x99FFFFFF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Right: property type label only (area moved top-right)
                            if (listing.propertyType != null)
                              Text(
                                listing.propertyType!.label,
                                style: AppTypography.priceTag.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Broker info row ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openBrokerProfile,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.navyLight,
                        backgroundImage: listing.brokerPhotoUrl != null
                            ? CachedNetworkImageProvider(
                                listing.brokerPhotoUrl!,
                                maxWidth: 80,
                                maxHeight: 80,
                              )
                            : null,
                        child: listing.brokerPhotoUrl == null
                            ? Text(
                                listing.brokerName.isNotEmpty
                                    ? listing.brokerName[0].toUpperCase()
                                    : 'B',
                                style: AppTypography.labelMedium.copyWith(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openBrokerProfile,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.brokerName,
                            style: AppTypography.labelMedium.copyWith(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (listing.posterRole != null)
                            _RoleBadge(role: listing.posterRole!),
                        ],
                      ),
                    ),
                  ),
                  // Time shown right-aligned before follow button
                  Text(
                    _timeAgo(listing.createdAt),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FollowButton(brokerUid: listing.brokerUid),
                ],
              ),
            ),

            // ── Description ─────────────────────────────────────────────────
            if (listing.description != null &&
                listing.description!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  listing.description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textOnDarkSecondary
                        : AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // ── Brokerage highlight — full-width thin gold strip ─────────────
            if (listing.brokerageAmount != null &&
                listing.brokerageAmount!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.08),
                  border: const Border(
                    left: BorderSide(color: AppColors.gold, width: 3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.handshake_rounded,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.brokerage,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        listing.brokerageAmount!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Action bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  // Like
                  _ActionButton(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor:
                        isLiked ? AppColors.error : AppColors.textSecondary,
                    label: _formatCount(listing.likesCount),
                    onTap: () =>
                        ref.read(feedProvider.notifier).toggleLike(listing),
                  ),
                  const SizedBox(width: 2),
                  // Comments (display-only for now)
                  _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: AppColors.textSecondary,
                    label: _formatCount(listing.commentsCount),
                    onTap: () {},
                  ),
                  const SizedBox(width: 2),
                  // Views
                  _ActionButton(
                    icon: Icons.remove_red_eye_outlined,
                    iconColor: AppColors.textSecondary,
                    label: _formatCount(listing.viewsCount),
                    onTap: null,
                  ),
                  const SizedBox(width: 2),
                  _LeadsBadge(listing: listing),
                  const Spacer(),
                  // Share icon only
                  _ActionButton(
                    icon: Icons.share_outlined,
                    iconColor: AppColors.textSecondary,
                    label: '',
                    onTap: _share,
                  ),
                  const SizedBox(width: 6),
                  // Contact Lead Owner CTA
                  GestureDetector(
                    onTap: _phoneRevealed ? null : _onContactTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _phoneRevealed
                            ? AppColors.success.withValues(alpha: 0.12)
                            : Colors.transparent,
                        border: Border.all(
                          color: _phoneRevealed
                              ? AppColors.success
                              : AppColors.gold,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: _phoneRevealed
                                ? AppColors.success
                                : AppColors.gold,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _phoneRevealed
                                ? (listing.brokerPhone?.isNotEmpty == true
                                    ? '+91 ${listing.brokerPhone}'
                                    : 'No number')
                                : l.inquiry,
                            style: AppTypography.labelSmall.copyWith(
                              color: _phoneRevealed
                                  ? AppColors.success
                                  : AppColors.gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

String _formatCount(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navyDark.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Text(
        listing.category.label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  Color get _color => switch (role) {
    'broker'   => const Color(0xFF1565C0),
    'investor' => const Color(0xFF2E7D32),
    'owner'    => const Color(0xFFE65100),
    'builder'  => const Color(0xFF6A1B9A),
    _          => AppColors.navyMid,
  };

  String get _label => switch (role) {
    'broker'   => '🏢 Broker',
    'investor' => '💰 Investor',
    'owner'    => '🏠 Owner',
    'builder'  => '🏗️ Builder',
    _          => role,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: AppTypography.labelSmall.copyWith(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Follow button ─────────────────────────────────────────────────────────────

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.brokerUid});
  final String brokerUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(
      authStateChangesProvider.select((s) => s.valueOrNull?.uid ?? ''),
    );
    if (myUid == brokerUid) return const SizedBox.shrink();

    final status = ref.watch(
      networkProvider.select((s) => s.statusFor(brokerUid)),
    );

    if (status == ConnectionStatus.following) {
      return _chip(
        label: 'Following',
        icon: Icons.check_rounded,
        color: AppColors.success,
        onTap: null,
      );
    }
    return _chip(
      label: 'Follow',
      icon: Icons.person_add_alt_1_rounded,
      color: AppColors.gold,
      onTap: () => ref.read(networkProvider.notifier).follow(brokerUid),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap != null ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: onTap != null ? 0.5 : 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadsBadge extends ConsumerWidget {
  const _LeadsBadge({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      crmProvider.select((s) => s.leadsForListing(listing.id)),
    );

    final hasLeads = count > 0;
    final color = hasLeads ? AppColors.gold : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ListingLeadsSheet(listing: listing),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: hasLeads ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: hasLeads ? 0.5 : 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasLeads ? Icons.assignment_rounded : Icons.assignment_outlined,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              hasLeads ? '$count ${count == 1 ? 'Lead' : 'Leads'}' : 'Leads',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Dual price tag (Flipkart style) ───────────────────────────────────────────

class _DualPrice extends StatelessWidget {
  const _DualPrice({required this.listing, this.dealFontSize = 22});

  final Listing listing;
  final double dealFontSize;

  @override
  Widget build(BuildContext context) {
    final discount = listing.discountPercent;
    final hasDiscount = discount != null && discount > 0;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        // Deal / asking price — always shown
        Text(
          listing.priceLabel,
          style: AppTypography.priceTag.copyWith(
            fontSize: dealFontSize,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
        ),

        if (hasDiscount) ...[
          // Original / MRP with strikethrough
          Text(
            listing.originalPriceLabel!,
            style: TextStyle(
              color: Colors.white60,
              fontSize: dealFontSize * 0.62,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white60,
              decorationThickness: 1.5,
            ),
          ),
          // Savings badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$discount% off',
              style: TextStyle(
                color: Colors.white,
                fontSize: dealFontSize * 0.48,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
