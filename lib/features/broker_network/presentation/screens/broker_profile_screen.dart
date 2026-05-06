import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/services/deep_link_service.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';
import 'package:cpapp/features/broker_network/presentation/providers/network_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/domain/entities/listing_category.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';

const _navy = Color(0xFF0A1628);
const _gold = Color(0xFFD4A843);

class BrokerProfileScreen extends ConsumerWidget {
  const BrokerProfileScreen({super.key, required this.brokerId});

  final String brokerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkProvider);

    // Try to find the broker in already-loaded state first
    BrokerProfile? broker;
    String? connectionId;

    final fromBrokers = networkState.brokers
        .where((b) => b.uid == brokerId)
        .toList();
    if (fromBrokers.isNotEmpty) broker = fromBrokers.first;

    // Find the connection document id for this broker
    for (final c in networkState.connections) {
      if (c.followerId == brokerId || c.followingId == brokerId) {
        connectionId = c.id;
        break;
      }
    }

    if (broker == null) {
      return _LoadingProfile(brokerId: brokerId, connectionId: connectionId);
    }

    final status = networkState.statusFor(brokerId);

    return _ProfileView(
      broker: broker,
      connectionId: connectionId,
      status: status,
    );
  }
}

// ── Fetches broker from Firestore when not in local state ─────────────────────

class _LoadingProfile extends ConsumerStatefulWidget {
  const _LoadingProfile({required this.brokerId, required this.connectionId});
  final String brokerId;
  final String? connectionId;

  @override
  ConsumerState<_LoadingProfile> createState() => _LoadingProfileState();
}

class _LoadingProfileState extends ConsumerState<_LoadingProfile> {
  BrokerProfile? _broker;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_fetch);
  }

  Future<void> _fetch() async {
    final result = await ref
        .read(networkRepositoryProvider)
        .fetchBrokerProfile(widget.brokerId);
    result.fold(
      (f) => setState(() => _error = f.message),
      (b) => setState(() => _broker = b),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_broker == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = ref.watch(
      networkProvider.select((s) => s.statusFor(widget.brokerId)),
    );

    return _ProfileView(
      broker: _broker!,
      connectionId: widget.connectionId,
      status: status,
    );
  }
}

// ── Main profile view ─────────────────────────────────────────────────────────

class _ProfileView extends ConsumerWidget {
  const _ProfileView({
    required this.broker,
    required this.connectionId,
    required this.status,
  });

  final BrokerProfile broker;
  final String? connectionId;
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(brokerListingsProvider(broker.uid));
    final mutualAsync = ref.watch(mutualConnectionsCountProvider(broker.uid));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _ProfileAppBar(
            broker: broker,
            connectionId: connectionId,
            status: status,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats ───────────────────────────────────────────────
                  _StatsRow(
                    broker: broker,
                    mutualCount: mutualAsync.valueOrNull ?? 0,
                  ),
                  const SizedBox(height: 24),

                  // ── About / Location ────────────────────────────────────
                  const _SectionLabel('About'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (broker.city != null)
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          label: broker.city!,
                        ),
                      if (broker.reraNumber != null)
                        _InfoChip(
                          icon: Icons.verified_user_outlined,
                          label: broker.reraNumber!,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Work Categories (derived from listings) ──────────────
                  listingsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (listings) {
                      if (listings.isEmpty) return const SizedBox.shrink();
                      final categories = listings
                          .map((l) => l.category)
                          .toSet()
                          .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Specialises In'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories
                                .map((c) => _CategoryChip(category: c))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // ── Listings ────────────────────────────────────────────
                  Row(
                    children: [
                      const _SectionLabel('Listings'),
                      const Spacer(),
                      listingsAsync.when(
                        data: (l) => Text(
                          '${l.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  listingsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: _gold),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Could not load listings',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    data: (listings) {
                      if (listings.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No listings yet',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: listings
                            .map((l) => _ListingTile(listing: l))
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

// ── Sliver app bar ────────────────────────────────────────────────────────────

class _ProfileAppBar extends ConsumerWidget {
  const _ProfileAppBar({
    required this.broker,
    required this.connectionId,
    required this.status,
  });

  final BrokerProfile broker;
  final String? connectionId;
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _navy,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.link_rounded),
          tooltip: 'Copy profile link',
          onPressed: () {
            final user = ref.read(authStateChangesProvider).valueOrNull;
            final refCode = user?.effectiveReferralCode
                ?? broker.uid.substring(0, 8).toUpperCase();
            final link = DeepLinkService.brokerUri(broker.uid, refCode).toString();
            Clipboard.setData(ClipboardData(text: link));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile link copied!'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share profile',
          onPressed: () {
            final user = ref.read(authStateChangesProvider).valueOrNull;
            final refCode = user?.effectiveReferralCode
                ?? broker.uid.substring(0, 8).toUpperCase();
            final text = DeepLinkService.brokerShareText(
              brokerName: broker.name,
              city: broker.city,
              brokerId: broker.uid,
              referralCode: refCode,
            );
            Share.share(text, subject: '${broker.name} on CPApp');
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy, Color(0xFF1A2E4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Avatar + name
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  _LargeAvatar(broker: broker),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                broker.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (broker.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF22C55E),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        if (broker.city != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                broker.city!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        _ConnectButton(
                          broker: broker,
                          connectionId: connectionId,
                          status: status,
                        ),
                      ],
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

// ── Large avatar ──────────────────────────────────────────────────────────────

class _LargeAvatar extends StatelessWidget {
  const _LargeAvatar({required this.broker});
  final BrokerProfile broker;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          backgroundImage: broker.photoUrl != null
              ? CachedNetworkImageProvider(broker.photoUrl!)
              : null,
          child: broker.photoUrl == null
              ? Text(
                  broker.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                )
              : null,
        ),
        if (broker.isVerified)
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
              child: const Icon(Icons.verified, size: 16, color: Color(0xFF22C55E)),
            ),
          ),
      ],
    );
  }
}

// ── Connect button in the app bar ─────────────────────────────────────────────

class _ConnectButton extends ConsumerWidget {
  const _ConnectButton({
    required this.broker,
    required this.connectionId,
    required this.status,
  });

  final BrokerProfile broker;
  final String? connectionId;
  final ConnectionStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status == ConnectionStatus.following) {
      return _GoldButton(
        label: 'Following',
        onTap: connectionId == null
            ? null
            : () => ref.read(networkProvider.notifier).unfollow(
                  connectionId: connectionId!,
                  otherUid: broker.uid,
                ),
      );
    }
    return _GoldButton(
      label: 'Follow',
      onTap: () => ref.read(networkProvider.notifier).follow(broker.uid),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _gold,
        foregroundColor: _navy,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minimumSize: const Size(120, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.broker, required this.mutualCount});
  final BrokerProfile broker;
  final int mutualCount;

  @override
  Widget build(BuildContext context) {
    final divider = Container(width: 1, height: 40, color: Colors.grey[300]);
    return Container(
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: broker.listingsCount.toString(),
              label: 'Listings',
            ),
          ),
          divider,
          Expanded(
            child: _StatCell(
              value: broker.connectionsCount.toString(),
              label: 'Followers',
            ),
          ),
          divider,
          Expanded(
            child: _StatCell(
              value: mutualCount.toString(),
              label: 'Mutual',
              highlight: mutualCount > 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.highlight = false,
  });
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? _gold : _navy,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

// ── Section helpers ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _navy,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Info chip (location, RERA) ────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _navy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 13,
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
            category.localizedLabel(Localizations.localeOf(context).languageCode),
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

// ── Compact listing tile (used in broker + own profile) ───────────────────────

class _ListingTile extends StatelessWidget {
  const _ListingTile({required this.listing});
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        Routes.listingDetail.replaceFirst(':listingId', listing.id),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
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
                      Container(color: Colors.grey.shade100),
                  errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    child: const Icon(
                      Icons.apartment_rounded,
                      color: _gold,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
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
                      '${listing.category.emoji} ${listing.category.localizedLabel(Localizations.localeOf(context).languageCode)}',
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
                      color: _navy,
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
                          color: _gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (listing.propertyType != null) ...[
                        const Text(
                          '  ·  ',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          listing.propertyType!.label,
                          style: TextStyle(
                            color: Colors.grey[600],
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
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
