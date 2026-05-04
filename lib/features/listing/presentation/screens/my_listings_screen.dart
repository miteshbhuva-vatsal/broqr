import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/feed/presentation/widgets/feed_card.dart';
import 'package:cpapp/features/listing/presentation/providers/listing_providers.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(myListingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.white : AppColors.navyDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Listings',
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
          ),
        ),
        actions: [
          if (!state.isLoading)
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? AppColors.white : AppColors.navyDark,
              ),
              onPressed: () => ref.read(myListingsProvider.notifier).refresh(),
            ),
        ],
      ),
      body: _Body(state: state),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});
  final MyListingsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(myListingsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.apartment_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No listings yet',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to post your first listing',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myListingsProvider.notifier).refresh(),
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: state.listings.length,
        itemBuilder: (_, i) => FeedCard(listing: state.listings[i]),
      ),
    );
  }
}
