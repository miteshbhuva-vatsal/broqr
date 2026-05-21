import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/services/deep_link_service.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/crm/presentation/widgets/listing_leads_sheet.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';

// ignore: unused_import — kept for InquireSheet used in listing_detail_screen
// import 'package:cpapp/features/feed/presentation/widgets/inquire_sheet.dart';

class FeedCard extends ConsumerStatefulWidget {
  const FeedCard({super.key, required this.listing});

  final Listing listing;

  @override
  ConsumerState<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends ConsumerState<FeedCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openBrokerProfile() {
    final listing = widget.listing;
    final myUid =
        ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';
    if (listing.brokerUid == myUid) {
      context.push(Routes.profile);
    } else {
      context.push(
        Routes.realtorProfile.replaceFirst(':realtorId', listing.brokerUid),
      );
    }
  }

  void _goToDetail() {
    ref.read(feedProvider.notifier).trackView(widget.listing);
    context.push(
      Routes.listingDetail.replaceFirst(':listingId', widget.listing.id),
    );
  }

  Future<void> _shareListing() async {
    final l = widget.listing;
    final user = ref.read(authStateChangesProvider).valueOrNull;
    final refCode = user?.effectiveReferralCode ?? l.brokerUid.substring(0, 8).toUpperCase();
    final text = DeepLinkService.listingShareText(
      emoji: l.category.emoji,
      category: l.category.label,
      location: l.location,
      city: l.city,
      price: l.priceLabel,
      area: l.area > 0 ? '${l.area.toStringAsFixed(0)} sq ft' : '',
      brokerName: l.brokerName,
      listingId: l.id,
      referralCode: refCode,
    );
    await Share.share(text, subject: '${l.category.label} on DigiProp');
  }

  void _showOwnerMenu(Listing listing) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _OwnerMenuSheet(
        listing: listing,
        onEdit: () {
          Navigator.pop(context);
          ref.read(addListingProvider.notifier).loadForEdit(listing);
          context.push(Routes.addListing);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(listing);
        },
      ),
    );
  }

  void _confirmDelete(Listing listing) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
            'This will permanently remove the listing. This action cannot be undone.',),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ref
                  .read(listingRepositoryProvider)
                  .deleteListing(listingId: listing.id);
              result.fold(
                (f) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: ${f.message}')),
                ),
                (_) {
                  ref.read(feedProvider.notifier).refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Listing deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final listing = widget.listing;
    final myUid = ref.watch(
      authStateChangesProvider.select((s) => s.valueOrNull?.uid ?? ''),
    );
    final isBuyer = ref.watch(
      authStateChangesProvider.select((s) => s.valueOrNull?.isBuyer ?? false),
    );
    final isMyPost = listing.brokerUid == myUid;
    // select() means this card only rebuilds when ITS liked/contacted state changes.
    final isLiked = ref.watch(
      feedProvider.select((s) => s.isLiked(listing.id)),
    );
    final isInquired = ref.watch(
      feedProvider.select((s) => s.isContacted(listing.id)),
    );

    return GestureDetector(
      onTap: () {
        ref.read(feedProvider.notifier).trackView(listing);
        context.push(
          Routes.listingDetail.replaceFirst(':listingId', listing.id),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                      memCacheWidth: 800,
                      memCacheHeight: 600,
                      fadeInDuration: const Duration(milliseconds: 180),
                      fadeOutDuration: Duration.zero,
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
                    // Gradient: light top, clear mid, heavy navy bottom
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.0, 0.45, 1.0],
                          colors: [
                            Color(0x33000000),
                            Colors.transparent,
                            Color(0xF20C1E3C),
                          ],
                        ),
                      ),
                    ),
                    // Category badge + edit button — top-right
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMyPost) ...[
                            GestureDetector(
                              onTap: () => _showOwnerMenu(listing),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.navyDark.withValues(
                                    alpha: 0.78,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 14,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          _CategoryBadge(listing: listing),
                        ],
                      ),
                    ),
                    // ── Price (left) + Like/View/Contacts (right) ──────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _DualPrice(
                                listing: listing,
                                dealFontSize: 24,
                              ),
                            ),
                            // Like
                            GestureDetector(
                              onTap: () => ref
                                  .read(feedProvider.notifier)
                                  .toggleLike(listing),
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 18,
                                    color: isLiked
                                        ? AppColors.error
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatCount(listing.likesCount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Views
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _formatCount(listing.viewsCount),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (listing.contactsCount > 0) ...[
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.people_alt_outlined,
                                    size: 16,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatCount(listing.contactsCount),
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Property info: title, location, type+area ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (big)
                  if (listing.title != null && listing.title!.isNotEmpty)
                    Text(
                      listing.title!,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark ? AppColors.white : AppColors.navyDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (listing.title != null && listing.title!.isNotEmpty)
                    const SizedBox(height: 4),
                  // Location, City
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${listing.location}, ${listing.city}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textOnDarkSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  // Property type + Area + Brokerage chips row
                  if (listing.propertyType != null ||
                      listing.area > 0 ||
                      (listing.brokerageAmount?.isNotEmpty ?? false) ||
                      (listing.instagramUrl?.isNotEmpty ?? false) ||
                      (listing.pdfUrl?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (listing.propertyType != null)
                          _InfoChip(
                            label:
                                '${listing.propertyType!.emoji} ${listing.propertyType!.label}',
                            isDark: isDark,
                          ),
                        if (listing.area > 0)
                          _InfoChip(
                            label: '📐 ${listing.areaLabel}',
                            isDark: isDark,
                          ),
                        if (listing.brokerageAmount?.isNotEmpty ?? false)
                          _BrokerageChip(
                            amount: listing.brokerageAmount!,
                            isDark: isDark,
                          ),
                        if (listing.instagramUrl?.isNotEmpty ?? false)
                          _InstagramChip(
                            url: listing.instagramUrl!,
                            isDark: isDark,
                          ),
                        if (listing.pdfUrl?.isNotEmpty ?? false)
                          _PdfChip(
                            url: listing.pdfUrl!,
                            listingId: listing.id,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ],
                  // Description — full text, emojis + newlines render naturally
                  if (listing.description != null &&
                      listing.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      listing.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textSecondary,
                        height: 1.5,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // ── Bottom bar: broker info + inquiry ───────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
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
                        radius: 18,
                        backgroundColor: AppColors.navyLight,
                        backgroundImage: listing.brokerPhotoUrl != null
                            ? CachedNetworkImageProvider(
                                listing.brokerPhotoUrl!,
                                maxWidth: 70,
                                maxHeight: 70,
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
                        mainAxisSize: MainAxisSize.min,
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
                          Row(
                            children: [
                              if (listing.posterRole != null) ...[
                                Flexible(
                                  child: _RoleBadge(role: listing.posterRole!),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  _timeAgo(listing.createdAt),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _shareListing,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!isBuyer) _LeadsBadge(listing: listing),
                  if (!isMyPost) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _goToDetail,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isInquired ? null : AppColors.goldGradient,
                          color: isInquired
                              ? AppColors.success.withValues(alpha: 0.12)
                              : null,
                          borderRadius: BorderRadius.circular(22),
                          border: isInquired
                              ? Border.all(color: AppColors.success, width: 1.5)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isInquired
                                  ? Icons.check_circle_rounded
                                  : Icons.open_in_new_rounded,
                              size: 13,
                              color: isInquired
                                  ? AppColors.success
                                  : AppColors.navyDark,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isInquired ? 'Inquired' : l.inquiry,
                              style: AppTypography.labelSmall.copyWith(
                                color: isInquired
                                    ? AppColors.success
                                    : AppColors.navyDark,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ),  // ClipRRect
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
        listing.category.localizedLabel(Localizations.localeOf(context).languageCode),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
              hasLeads
                ? '$count ${count == 1 ? AppLocalizations.of(context).lead : AppLocalizations.of(context).leads}'
                : AppLocalizations.of(context).leads,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BrokerageChip extends StatelessWidget {
  const _BrokerageChip({required this.amount, required this.isDark});
  final String amount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Split "2.5%" → numeric "2.5" + symbol "%"
    final hasPercent = amount.contains('%');
    final numeric = hasPercent ? amount.replaceAll('%', '').trim() : amount;
    final symbol  = hasPercent ? '%' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.offWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.6 : 0.7),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: AppTypography.labelSmall.copyWith(fontSize: 11),
          children: [
            const TextSpan(text: '🤝 '),
            TextSpan(
              text: 'Brokerage ',
              style: TextStyle(
                color: isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: numeric,
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: symbol,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
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

// ── Edit listing bottom sheet ─────────────────────────────────────────────────

class _EditListingSheet extends ConsumerStatefulWidget {
  const _EditListingSheet({required this.listing, required this.onSaved});
  final Listing listing;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EditListingSheet> createState() => _EditListingSheetState();
}

class _EditListingSheetState extends ConsumerState<_EditListingSheet> {
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _brokerage;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title       = TextEditingController(text: widget.listing.title ?? '');
    _price       = TextEditingController(
        text: widget.listing.price > 0
            ? widget.listing.price.toStringAsFixed(
                widget.listing.price % 1 == 0 ? 0 : 2,
              )
            : '',);
    _brokerage   = TextEditingController(text: widget.listing.brokerageAmount ?? '');
    _description = TextEditingController(text: widget.listing.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _brokerage.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final priceText = _price.text.trim();
    final result = await ref.read(listingRepositoryProvider).updateListing(
          listingId: widget.listing.id,
          title: _title.text.trim(),
          price: priceText.isEmpty
              ? null
              : (double.tryParse(priceText) ?? widget.listing.price),
          brokerageAmount: _brokerage.text.trim(),
          description: _description.text.trim(),
        );
    if (!mounted) return;
    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${failure.message}')),
        );
        setState(() => _saving = false);
      },
      (_) {
        widget.onSaved();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Listing',
              style: AppTypography.titleMedium.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _Field(ctrl: _title, label: 'Title', isDark: isDark),
            const SizedBox(height: 12),
            _Field(
              ctrl: _price,
              label: 'Price (₹)',
              isDark: isDark,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            _Field(ctrl: _brokerage, label: 'Brokerage %', isDark: isDark),
            const SizedBox(height: 12),
            _Field(
              ctrl: _description,
              label: 'Description',
              isDark: isDark,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyDark,
                  disabledBackgroundColor:
                      AppColors.navyDark.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.label,
    required this.isDark,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController ctrl;
  final String label;
  final bool isDark;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? AppColors.white : AppColors.navyDark,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.navyMid.withValues(alpha: 0.3)
            : AppColors.offWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.navyLight, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Instagram icon + chip ─────────────────────────────────────────────────────

class _InstagramIcon extends StatelessWidget {
  const _InstagramIcon({required this.size});
  final double size;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFF9A825), Color(0xFFF4511E), Color(0xFFAD1457), Color(0xFF6A1B9A)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => _gradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Icon(Icons.camera_alt_rounded, size: size, color: Colors.white),
    );
  }
}

class _InstagramChip extends StatelessWidget {
  const _InstagramChip({required this.url, required this.isDark});
  final String url;
  final bool isDark;

  Future<void> _launch() async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.offWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _InstagramIcon(size: 12),
            const SizedBox(width: 4),
            Text(
              'Instagram',
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
    );
  }
}

// ── Owner menu bottom sheet ───────────────────────────────────────────────────

class _OwnerMenuSheet extends StatelessWidget {
  const _OwnerMenuSheet({
    required this.listing,
    required this.onEdit,
    required this.onDelete,
  });
  final Listing listing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: AppColors.gold),
            title: Text(
              'Edit Listing',
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.navyDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: onEdit,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: const Text(
              'Delete Listing',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── PDF chip ──────────────────────────────────────────────────────────────────

class _PdfChip extends StatefulWidget {
  const _PdfChip({
    required this.url,
    required this.listingId,
    required this.isDark,
  });
  final String url;
  final String listingId;
  final bool isDark;

  @override
  State<_PdfChip> createState() => _PdfChipState();
}

class _PdfChipState extends State<_PdfChip> {
  bool _downloading = false;
  double? _progress;

  Future<String> _localPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/listing_pdfs');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return '${folder.path}/${widget.listingId}.pdf';
  }

  Future<void> _handleTap() async {
    if (_downloading) return;
    final path = await _localPath();
    final file = File(path);
    if (!file.existsSync()) {
      if (!mounted) return;
      setState(() { _downloading = true; _progress = 0; });
      try {
        await Dio().download(
          widget.url,
          path,
          onReceiveProgress: (received, total) {
            if (mounted && total > 0) {
              setState(() { _progress = received / total; });
            }
          },
        );
      } catch (_) {
        if (mounted) {
          setState(() { _downloading = false; _progress = null; });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed')),
          );
        }
        return;
      }
      if (!mounted) return;
      setState(() { _downloading = false; _progress = null; });
    }
    if (!mounted) return;
    _showOptions(path);
  }

  void _showOptions(String path) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Property Document'),
        content: const Text('Open or share the PDF brochure.'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); OpenFilex.open(path); },
            child: const Text('Open'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(path)], text: 'Property Document');
            },
            child: const Text('Share'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.surfaceDark : AppColors.offWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_downloading && _progress != null)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 1.5,
                  color: const Color(0xFFE53935),
                ),
              )
            else
              const Icon(Icons.picture_as_pdf_rounded,
                  size: 12, color: Color(0xFFE53935),),
            const SizedBox(width: 4),
            Text(
              _downloading ? 'Downloading…' : 'PDF',
              style: AppTypography.labelSmall.copyWith(
                color: widget.isDark
                    ? AppColors.textOnDarkSecondary
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
