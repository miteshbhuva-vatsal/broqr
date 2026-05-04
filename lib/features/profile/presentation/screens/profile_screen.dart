import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/domain/entities/app_user.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/crm/presentation/providers/crm_providers.dart';
import 'package:cpapp/features/listing/domain/entities/listing.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';
import 'package:cpapp/shared/widgets/app_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateChangesProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Failed to load profile')),
      ),
      data: (user) {
        if (user == null) return const Scaffold(body: SizedBox.shrink());
        return _ProfileBody(user: user);
      },
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final leadsCount = ref.watch(crmProvider.select((s) => s.activeCount));

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          _ProfileHeader(user: user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StatsRow(
                    listings: user.listingsCount,
                    connections: user.connectionsCount,
                    leadsCount: leadsCount,
                    onListingsTap: () => context.push(Routes.myListings),
                    onNetworkTap: () => context.push(Routes.network),
                    onLeadsTap: () => context.go(Routes.crm),
                  ),
                  const SizedBox(height: 16),
                  _NetworkTile(connections: user.connectionsCount),
                  const SizedBox(height: 28),
                  const _SectionTitle('Contact Info'),
                  const SizedBox(height: 12),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Mobile',
                    value: user.mobile != null
                        ? '+91 ${user.mobile}'
                        : 'Not set',
                    isEmpty: user.mobile == null,
                  ),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email.isNotEmpty ? user.email : 'Not set',
                    isEmpty: user.email.isEmpty,
                  ),
                  if (user.city != null) ...[
                    const SizedBox(height: 10),
                    _InfoTile(
                      icon: Icons.location_city_outlined,
                      label: 'City',
                      value: user.city!,
                    ),
                  ],
                  if (user.reraNumber != null &&
                      user.reraNumber!.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionTitle('Verification'),
                    const SizedBox(height: 12),
                    _InfoTile(
                      icon: Icons.verified_user_outlined,
                      label: 'RERA Number',
                      value: user.reraNumber!,
                      valueColor: AppColors.success,
                    ),
                  ],
                  const SizedBox(height: 40),
                  AppButton(
                    label: 'Sign Out',
                    variant: AppButtonVariant.outline,
                    prefixIcon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => _confirmSignOut(context, ref),
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    _SeedButton(user: user),
                  ],
                  const SizedBox(height: 32),
                  _MyListingsSection(uid: user.uid, isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

// ── Debug seed button ─────────────────────────────────────────────────────────

class _SeedButton extends StatelessWidget {
  const _SeedButton({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.push(Routes.devSeed),
      icon: const Icon(Icons.science_outlined, size: 16, color: Colors.white38),
      label: const Text(
        '⚙ Seed data',
        style: TextStyle(color: Colors.white38, fontSize: 12),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.navyDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.navyGradient,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                _Avatar(user: user),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : 'Broker',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (user.city != null)
                  Text(
                    user.city!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').map((w) => w[0]).take(2).join()
        : '?';

    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.gold,
      backgroundImage:
          user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
      child: user.photoUrl == null
          ? Text(
              initials.toUpperCase(),
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.navyDark,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.listings,
    required this.connections,
    required this.leadsCount,
    required this.onListingsTap,
    required this.onNetworkTap,
    required this.onLeadsTap,
  });
  final int listings;
  final int connections;
  final int leadsCount;
  final VoidCallback onListingsTap;
  final VoidCallback onNetworkTap;
  final VoidCallback onLeadsTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = Container(
      width: 1, height: 48,
      color: isDark ? AppColors.borderDark : AppColors.border,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onListingsTap,
              behavior: HitTestBehavior.opaque,
              child: _StatCell(
                value: listings.toString(),
                label: 'Listings',
                icon: Icons.apartment_rounded,
                showArrow: true,
              ),
            ),
          ),
          divider,
          Expanded(
            child: GestureDetector(
              onTap: onNetworkTap,
              behavior: HitTestBehavior.opaque,
              child: _StatCell(
                value: connections.toString(),
                label: 'Network',
                icon: Icons.people_outline_rounded,
                showArrow: true,
              ),
            ),
          ),
          divider,
          Expanded(
            child: GestureDetector(
              onTap: onLeadsTap,
              behavior: HitTestBehavior.opaque,
              child: _StatCell(
                value: leadsCount.toString(),
                label: 'Leads',
                icon: Icons.assignment_outlined,
                valueColor: leadsCount > 0 ? AppColors.gold : null,
                showArrow: true,
              ),
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
    required this.icon,
    this.valueColor,
    this.showArrow = false,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color? valueColor;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = valueColor ?? (isDark ? AppColors.white : AppColors.navyDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: AppTypography.titleLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (showArrow)
                Icon(Icons.chevron_right_rounded, size: 16, color: textColor),
            ],
          ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isEmpty
                        ? AppColors.textHint
                        : (valueColor ??
                            (isDark
                                ? AppColors.white
                                : AppColors.textPrimary)),
                    fontStyle:
                        isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── My Listings section (own profile) ─────────────────────────────────────────

class _MyListingsSection extends ConsumerWidget {
  const _MyListingsSection({required this.uid, required this.isDark});
  final String uid;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(brokerListingsProvider(uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _SectionTitle('My Listings'),
            const Spacer(),
            listingsAsync.whenOrNull(
              data: (l) => Text(
                '${l.length}',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ) ??
                const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 12),
        listingsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          ),
          error: (_, __) => Text(
            'Could not load listings',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          data: (listings) {
            if (listings.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No listings yet — tap + to post one',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                ),
              );
            }
            return Column(
              children: listings
                  .map((l) => _ProfileListingTile(listing: l, isDark: isDark))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileListingTile extends StatelessWidget {
  const _ProfileListingTile({required this.listing, required this.isDark});
  final Listing listing;
  final bool isDark;

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
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
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
                  placeholder: (_, __) => Container(
                    color: isDark ? AppColors.navyMid : AppColors.surfaceLight,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: isDark ? AppColors.navyMid : AppColors.surfaceLight,
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
                      '${listing.category.emoji} ${listing.category.label}',
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
                    style: AppTypography.labelMedium.copyWith(
                      color: isDark ? AppColors.white : AppColors.textPrimary,
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
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      if (listing.propertyType != null) ...[
                        Text(
                          '  ·  ',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                        Text(
                          listing.propertyType!.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
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
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Network entry tile shown on profile ───────────────────────────────────────

class _NetworkTile extends StatelessWidget {
  const _NetworkTile({required this.connections});
  final int connections;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push(Routes.network),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                color: AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: AppColors.gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Network',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.white : AppColors.navyDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    connections > 0
                        ? '$connections broker${connections == 1 ? '' : 's'} connected'
                        : 'Browse and connect with brokers',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
