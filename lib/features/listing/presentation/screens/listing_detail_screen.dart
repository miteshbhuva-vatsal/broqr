import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/core/services/deep_link_service.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/feed/presentation/providers/feed_providers.dart';
import 'package:cpapp/features/listing/data/services/listing_pdf_service.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/presentation/widgets/listing_leads_sheet.dart';
import 'package:cpapp/features/crm/presentation/screens/lead_detail_screen.dart';
import 'package:cpapp/features/notifications/domain/entities/app_notification.dart';
import 'package:cpapp/features/notifications/presentation/providers/notification_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailScreen> createState() =>
      _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _currentImage = 0;
  bool _pdfLoading = false;
  bool _phoneRevealed = false;
  final _shareKey = GlobalKey();
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Listing? _findListing() {
    // Check feed cache first (instant, no Firestore call)
    final listings = ref.read(feedProvider).listings;
    try {
      return listings.firstWhere((l) => l.id == widget.listingId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _share(Listing l) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    final refCode = user?.effectiveReferralCode ??
        l.brokerUid.substring(0, 8).toUpperCase();

    final shareText = DeepLinkService.listingShareText(
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

    try {
      final boundary =
          _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/cpapp_listing.png';
      await File(path).writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(path)],
        text: shareText,
        subject: '${l.category.label} on DigiProp',
      );
    } catch (_) {
      await Share.share(shareText, subject: '${l.category.label} on DigiProp');
    }
  }

  Future<void> _sharePdf(Listing l) async {
    setState(() => _pdfLoading = true);
    try {
      final bytes = await ListingPdfService.generate(l);
      final filename = 'CPApp_${l.location.replaceAll(' ', '_')}_${l.city}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).couldNotLoadListings}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  Future<void> _onContactTap(Listing l) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;
    await _doContact(l);
  }

  Future<void> _doContact(Listing l) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null) return;

    final phone = user.mobile?.isNotEmpty == true ? user.mobile : null;

    final result = await ref.read(crmRepositoryProvider).createContactLead(
          brokerUid: l.brokerUid,
          clientName: user.name,
          clientPhone: phone,
          listingId: l.id,
          listingCity: l.city,
          listingPriceLabel: l.priceLabel,
        );

    final outcome = result.fold<ContactLeadOutcome?>(
      (_) => null,
      (o) => o,
    );

    // Notify the listing owner only when a fresh lead was actually created
    // (skip for self-contact and dedup'd retries).
    if (outcome == ContactLeadOutcome.created && user.uid != l.brokerUid) {
      final contactLine =
          phone != null ? '${user.name} • +91 $phone' : user.name;
      unawaited(
        ref.read(notificationRemoteDataSourceProvider).createNotification(
          recipientUid: l.brokerUid,
          type: NotificationType.newLead,
          title: '🔔 New Lead on your listing',
          body: '$contactLine is interested in your '
              '${l.category.label} in ${l.city}',
          actorUid: user.uid,
          targetId: l.id,
        ),
      );
    }

    // Mark as inquired in feed state + persist to Firestore for both outcomes
    // (created = fresh inquiry; alreadyExisted = repeat tap, already recorded).
    if (outcome != null) {
      unawaited(ref.read(feedProvider.notifier).markInquired(l.id));
    }

    if (!mounted) return;
    setState(() => _phoneRevealed = true);

    final brokerPhone = l.brokerPhone?.isNotEmpty == true ? l.brokerPhone : null;
    final String message;
    final Color bg;
    switch (outcome) {
      case ContactLeadOutcome.created:
        message = brokerPhone != null
            ? '✅ Your inquiry has been submitted to Lead Owner, you can contact him now with mobile number +91 $brokerPhone'
            : '✅ Your inquiry has been submitted to Lead Owner.';
        bg = AppColors.success;
      case ContactLeadOutcome.alreadyExisted:
        message = brokerPhone != null
            ? '📋 Inquiry already submitted. You can contact the Lead Owner at +91 $brokerPhone'
            : '📋 You already contacted this listing';
        bg = AppColors.navyMid;
      case null:
        message = brokerPhone == null
            ? AppLocalizations.of(context).noBrokerPhone
            : '✅ Broker contact revealed below';
        bg = AppColors.navyMid;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Feed cache hit — no async needed
    final cached = _findListing();
    // Cold-start deep link — fetch from Firestore
    final asyncListing = ref.watch(listingByIdProvider(widget.listingId));
    final listing = cached ?? asyncListing.valueOrNull;

    if (listing == null) {
      if (asyncListing.isLoading) {
        return Scaffold(
          backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final isLiked = ref.watch(
      feedProvider.select((s) => s.isLiked(listing.id)),
    );
    final isContacted = ref.watch(
      feedProvider.select((s) => s.isContacted(listing.id)),
    );
    final revealed = _phoneRevealed || isContacted;
    final myUid = ref.watch(authStateChangesProvider).valueOrNull?.uid ?? '';
    final isBuyer = ref.watch(
      authStateChangesProvider.select((s) => s.valueOrNull?.isBuyer ?? false),
    );
    final isMyListing = listing.brokerUid == myUid;
    final allImages = [listing.heroImageUrl, ...listing.additionalImageUrls];

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // ── Hero image app bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.52,
            pinned: true,
            backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
            actions: [
              // PDF brochure
              GestureDetector(
                onTap: _pdfLoading ? null : () => _sharePdf(listing),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: _pdfLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_outlined,
                          color: AppColors.gold,
                          size: 18,
                        ),
                ),
              ),
              // Image share
              GestureDetector(
                onTap: () => _share(listing),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
            flexibleSpace: RepaintBoundary(
              key: _shareKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -200 &&
                          _currentImage < allImages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                        );
                      } else if (v > 200 && _currentImage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allImages.length,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (_, i) => Stack(
                        fit: StackFit.expand,
                        children: [
                          // Blurred hero as instant placeholder for every image
                          Transform.scale(
                            scale: 1.15,
                            child: ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(
                                sigmaX: 28, sigmaY: 28,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: listing.heroImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: isDark
                                      ? AppColors.navyMid
                                      : AppColors.surfaceLight,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: isDark
                                      ? AppColors.navyMid
                                      : AppColors.surfaceLight,
                                ),
                              ),
                            ),
                          ),
                          // Full-res image fades in on top once downloaded
                          CachedNetworkImage(
                            imageUrl: allImages[i],
                            fit: BoxFit.cover,
                            memCacheWidth: 1080,
                            fadeInDuration:
                                const Duration(milliseconds: 350),
                            fadeOutDuration: Duration.zero,
                            placeholder: (_, __) => const SizedBox.shrink(),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceLight,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.textHint,
                                size: 48,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Subtle top gradient for back/action button readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x66000000), Colors.transparent],
                      ),
                    ),
                  ),
                  // DigiProp watermark
                  const Positioned(
                    top: 60,
                    right: 16,
                    child: Text(
                      'DigiProp',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Left tap area — go to previous image
                  if (allImages.length > 1)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 36,
                      width: 80,
                      child: GestureDetector(
                        onTap: () {
                          if (_currentImage > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                  // Right tap area — go to next image
                  if (allImages.length > 1)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 36,
                      width: 80,
                      child: GestureDetector(
                        onTap: () {
                          if (_currentImage < allImages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                  // Page indicator dots
                  if (allImages.length > 1)
                    Positioned(
                      bottom: 36,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          allImages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImage == i ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImage == i
                                  ? AppColors.gold
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Rounded cap — connects image to body seamlessly
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.navyDark
                            : AppColors.offWhite,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Price / title header block ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + property type badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            color: listing.category.color,
                            bgColor: listing.category.bgColor,
                            label:
                                '${listing.category.emoji}  ${listing.category.localizedLabel(Localizations.localeOf(context).languageCode)}',
                          ),
                          if (listing.propertyType != null)
                            _Badge(
                              color: AppColors.navyMid,
                              bgColor:
                                  AppColors.navyMid.withValues(alpha: 0.1),
                              label:
                                  '${listing.propertyType!.emoji}  ${listing.propertyType!.label}',
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      if (listing.title != null &&
                          listing.title!.isNotEmpty) ...[
                        Text(
                          listing.title!,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.white
                                : AppColors.navyDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Price
                      _DetailDualPrice(listing: listing),
                      const SizedBox(height: 10),

                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.gold,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${listing.location}, ${listing.city}',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textOnDarkSecondary
                                    : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Row 1 — Property type / area / brokerage chips
                      if (listing.propertyType != null ||
                          listing.area > 0 ||
                          (listing.brokerageAmount?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              if (listing.propertyType != null)
                                _DetailInfoChip(
                                  label:
                                      '${listing.propertyType!.emoji} ${listing.propertyType!.label}',
                                  isDark: isDark,
                                ),
                              if (listing.area > 0) ...[
                                const SizedBox(width: 8),
                                _DetailInfoChip(
                                  label: '📐 ${listing.areaLabel}',
                                  isDark: isDark,
                                ),
                              ],
                              if (listing.brokerageAmount?.isNotEmpty ??
                                  false) ...[
                                const SizedBox(width: 8),
                                _DetailBrokerageChip(
                                  amount: listing.brokerageAmount!,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Row 2 — Instagram & PDF links (always visible when present)
                      if ((listing.instagramUrl?.isNotEmpty ?? false) ||
                          (listing.pdfUrl?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (listing.instagramUrl?.isNotEmpty ?? false)
                              _DetailInstagramChip(
                                url: listing.instagramUrl!,
                                isDark: isDark,
                              ),
                            if ((listing.instagramUrl?.isNotEmpty ?? false) &&
                                (listing.pdfUrl?.isNotEmpty ?? false))
                              const SizedBox(width: 10),
                            if (listing.pdfUrl?.isNotEmpty ?? false)
                              _DetailPdfChip(
                                url: listing.pdfUrl!,
                                listingId: listing.id,
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Key specs card ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SpecsRow(listing: listing),
                ),
                const SizedBox(height: 16),

                // ── About / Description ───────────────────────────────────────
                if (listing.description != null &&
                    listing.description!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionCard(
                      isDark: isDark,
                      header: AppLocalizations.of(context).aboutThisProperty,
                      child: Text(
                        listing.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textOnDarkSecondary
                              : AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Broker card ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _BrokerCard(
                    listing: listing,
                    isDark: isDark,
                    phoneRevealed: revealed,
                    isMyListing: isMyListing,
                    onContactTap: () => _onContactTap(listing),
                  ),
                ),

                // ── Brokerage strip ───────────────────────────────────────────
                if (listing.brokerageAmount != null &&
                    listing.brokerageAmount!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: const Border(
                          left: BorderSide(color: AppColors.gold, width: 3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.handshake_rounded,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).brokerage,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
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
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Leads section (sellers only) ──────────────────────────────
                if (!isBuyer)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: _LeadsSection(listing: listing),
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom action bar ─────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.navyMid : AppColors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  // Like
                  _BottomAction(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    iconColor:
                        isLiked ? AppColors.error : AppColors.textSecondary,
                    label: '${listing.likesCount}',
                    onTap: () =>
                        ref.read(feedProvider.notifier).toggleLike(listing),
                  ),
                  const SizedBox(width: 8),
                  // Views
                  _BottomAction(
                    icon: Icons.remove_red_eye_outlined,
                    iconColor: AppColors.textSecondary,
                    label: '${listing.viewsCount}',
                    onTap: null,
                  ),
                  if (!isMyListing) ...[
                    const SizedBox(width: 12),
                    // Contact Lead Owner CTA
                    Expanded(
                      child: GestureDetector(
                        onTap: revealed ? null : () => _onContactTap(listing),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: revealed ? null : AppColors.goldGradient,
                            color: revealed
                                ? AppColors.success.withValues(alpha: 0.12)
                                : null,
                            border: revealed
                                ? Border.all(color: AppColors.success, width: 1.5)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                revealed
                                    ? Icons.check_circle_rounded
                                    : Icons.phone_outlined,
                                size: 16,
                                color: revealed
                                    ? AppColors.success
                                    : AppColors.navyDark,
                              ),
                              const SizedBox(width: 8),
                              Builder(
                                builder: (ctx) => Text(
                                  revealed
                                      ? 'Inquired'
                                      : AppLocalizations.of(ctx).contactLeadOwner,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: revealed
                                        ? AppColors.success
                                        : AppColors.navyDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section card helper ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.header,
    required this.child,
  });

  final bool isDark;
  final String header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                header,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({
    required this.color,
    required this.bgColor,
    required this.label,
  });

  final Color color;
  final Color bgColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SpecsRow extends StatelessWidget {
  const _SpecsRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).keySpecs,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 8,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SpecTile(
                icon: Icons.straighten_rounded,
                label: AppLocalizations.of(context).area,
                value: listing.areaLabel,
              ),
              _Divider(),
              _SpecTile(
                icon: Icons.location_city_rounded,
                label: AppLocalizations.of(context).city,
                value: listing.city,
              ),
              if (listing.propertyType != null) ...[
                _Divider(),
                _SpecTile(
                  icon: Icons.home_work_rounded,
                  label: AppLocalizations.of(context).type,
                  value: listing.propertyType!.label,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.gold, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppColors.white : AppColors.navyDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textHint,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

class _BrokerCard extends StatelessWidget {
  const _BrokerCard({
    required this.listing,
    required this.isDark,
    required this.phoneRevealed,
    required this.isMyListing,
    required this.onContactTap,
  });

  final Listing listing;
  final bool isDark;
  final bool phoneRevealed;
  final bool isMyListing;
  final VoidCallback onContactTap;

  Future<void> _call() async {
    final phone = listing.brokerPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: '+91$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = listing.brokerPhone != null && listing.brokerPhone!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyDark, AppColors.navyMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with gold ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.navyLight,
                  backgroundImage: listing.brokerPhotoUrl != null
                      ? CachedNetworkImageProvider(listing.brokerPhotoUrl!)
                      : null,
                  child: listing.brokerPhotoUrl == null
                      ? Text(
                          listing.brokerName.isNotEmpty
                              ? listing.brokerName[0].toUpperCase()
                              : 'B',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.brokerName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2,),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.4),),
                      ),
                      child: Text(
                        AppLocalizations.of(context).verifiedBroker,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Phone row — always shown, masked until revealed ──────────────
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: phoneRevealed
                ? Row(
                    key: const ValueKey('revealed'),
                    children: [
                      const Icon(Icons.phone_rounded,
                          size: 14, color: AppColors.gold,),
                      const SizedBox(width: 8),
                      Text(
                        hasPhone
                            ? '+91 ${listing.brokerPhone}'
                            : AppLocalizations.of(context).noNumber,
                        style: TextStyle(
                          color: hasPhone
                              ? AppColors.white
                              : AppColors.textOnDarkSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('masked'),
                    children: [
                      const Icon(Icons.lock_outline_rounded,
                          size: 14, color: AppColors.gold,),
                      const SizedBox(width: 8),
                      Text(
                        '+91 •••• ••••••',
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2,),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context).tapToReveal,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.gold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 14),

          // ── CTA button (hidden for own listings) ─────────────────────────
          if (!isMyListing)
          GestureDetector(
            onTap: phoneRevealed ? (hasPhone ? _call : null) : onContactTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 40,
              decoration: BoxDecoration(
                gradient: phoneRevealed ? null : AppColors.goldGradient,
                color: phoneRevealed
                    ? AppColors.success.withValues(alpha: 0.15)
                    : null,
                border: phoneRevealed
                    ? Border.all(color: AppColors.success, width: 1.5)
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    phoneRevealed
                        ? Icons.check_circle_rounded
                        : Icons.phone_outlined,
                    size: 15,
                    color: phoneRevealed
                        ? AppColors.success
                        : AppColors.navyDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    phoneRevealed
                        ? 'Inquired'
                        : AppLocalizations.of(context).contactLeadOwner,
                    style: AppTypography.labelMedium.copyWith(
                      color: phoneRevealed
                          ? AppColors.success
                          : AppColors.navyDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
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

class _BottomAction extends StatelessWidget {
  const _BottomAction({
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dual price tag for the detail hero overlay ────────────────────────────────

class _DetailDualPrice extends StatelessWidget {
  const _DetailDualPrice({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final discount = listing.discountPercent;
    final hasDiscount = discount != null && discount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          listing.priceLabel,
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                listing.originalPriceLabel!,
                style: TextStyle(
                  color: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: isDark
                      ? AppColors.textOnDarkSecondary
                      : AppColors.textSecondary,
                  decorationThickness: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '$discount% off',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Detail chip widgets ───────────────────────────────────────────────────────

class _DetailInfoChip extends StatelessWidget {
  const _DetailInfoChip({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? AppColors.white : AppColors.navyDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailBrokerageChip extends StatelessWidget {
  const _DetailBrokerageChip({required this.amount, required this.isDark});
  final String amount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final hasPercent = amount.contains('%');
    final numeric = hasPercent ? amount.replaceAll('%', '').trim() : amount;
    final symbol = hasPercent ? '%' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: isDark ? 0.6 : 0.7),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
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
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leads section shown at bottom of listing detail ────────────────────────────

class _LeadsSection extends ConsumerWidget {
  const _LeadsSection({required this.listing});
  final Listing listing;

  void _openLeadsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListingLeadsSheet(listing: listing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leads = ref.watch(
      crmProvider.select(
        (s) => s.leads.where((l) => l.linkedListingId == listing.id).toList(),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              AppLocalizations.of(context).leads,
              style: AppTypography.titleSmall.copyWith(
                color: isDark ? AppColors.white : AppColors.navyDark,
              ),
            ),
            if (leads.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${leads.length}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => _openLeadsSheet(context),
              child: Text(
                AppLocalizations.of(context).addLead,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (leads.isEmpty)
          GestureDetector(
            onTap: () => _openLeadsSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.gold,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context).trackLeadsForProperty,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children:
                leads.take(3).map((lead) => _LeadRow(lead: lead)).toList(),
          ),

        if (leads.length > 3)
          GestureDetector(
            onTap: () => _openLeadsSheet(context),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppLocalizations.of(context).viewAllLeads,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _LeadRow extends ConsumerWidget {
  const _LeadRow({required this.lead});
  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LeadDetailScreen(leadId: lead.id),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: lead.stage.color, width: 3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDark.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: lead.priority.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.clientName,
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lead.clientPhone != null)
                    Text(
                      lead.clientPhone!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: lead.stage.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lead.stage.label,
                style: AppTypography.labelSmall.copyWith(
                  color: lead.stage.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PDF chip (detail screen) ──────────────────────────────────────────────────

class _DetailPdfChip extends StatefulWidget {
  const _DetailPdfChip({
    required this.url,
    required this.listingId,
    required this.isDark,
  });
  final String url;
  final String listingId;
  final bool isDark;

  @override
  State<_DetailPdfChip> createState() => _DetailPdfChipState();
}

class _DetailPdfChipState extends State<_DetailPdfChip> {
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.surfaceDark : AppColors.offWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE53935).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_downloading && _progress != null)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 1.5,
                  color: const Color(0xFFE53935),
                ),
              )
            else
              const Icon(Icons.picture_as_pdf_rounded,
                  size: 14, color: Color(0xFFE53935),),
            const SizedBox(width: 5),
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

// ── Instagram chip (detail screen) ────────────────────────────────────────────

class _DetailInstagramChip extends StatelessWidget {
  const _DetailInstagramChip({required this.url, required this.isDark});
  final String url;
  final bool isDark;

  static const _gradient = LinearGradient(
    colors: [Color(0xFFF9A825), Color(0xFFF4511E), Color(0xFFAD1457), Color(0xFF6A1B9A)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  Future<void> _launch() async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.offWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => _gradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 5),
            Text(
              'Instagram',
              style: AppTypography.labelSmall.copyWith(
                color: isDark ? AppColors.textOnDarkSecondary : AppColors.textSecondary,
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
