import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/ask/presentation/providers/ask_providers.dart';
import 'package:cpapp/features/ask/presentation/widgets/ask_create_sheet.dart';
import 'package:cpapp/features/ask/presentation/widgets/ask_post_card.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/news/presentation/screens/news_screen.dart';

class AskScreen extends ConsumerWidget {
  const AskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeller = ref.watch(
      authStateChangesProvider.select((s) => s.valueOrNull?.isSeller ?? false),
    );

    return isSeller
        ? const _SellerAskNewsView()
        : const _AskOnly();
  }
}

// ── Seller view: tabbed Ask + News ────────────────────────────────────────────

class _SellerAskNewsView extends ConsumerWidget {
  const _SellerAskNewsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.surfaceLight,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
          elevation: 0,
          title: Text(
            l.askTitle,
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.white : AppColors.navyDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.gold, size: 28),
              tooltip: l.askPost,
              onPressed: () => _openCreateSheet(context),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.gold,
            indicatorWeight: 2.5,
            labelStyle: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Ask'),
              Tab(text: 'News'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AskBody(),
            const NewsFeedBody(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            final tab = DefaultTabController.of(ctx);
            return AnimatedBuilder(
              animation: tab,
              builder: (_, __) => tab.index == 0
                  ? FloatingActionButton(
                      onPressed: () => _openCreateSheet(context),
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                      child: const Icon(Icons.edit_rounded),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AskCreateSheet(),
    );
  }
}

// ── Buyer / standalone view: Ask only ─────────────────────────────────────────

class _AskOnly extends ConsumerWidget {
  const _AskOnly();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.white,
        elevation: 0,
        title: Text(
          l.askTitle,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.white : AppColors.navyDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.gold, size: 28),
            tooltip: l.askPost,
            onPressed: () => _openCreateSheet(context),
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          final state = ref.read(askFeedProvider);
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240 &&
              !state.isLoadingMore &&
              state.hasMore &&
              state.posts.isNotEmpty) {
            ref.read(askFeedProvider.notifier).loadOlder();
          }
          return false;
        },
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () => ref.read(askFeedProvider.notifier).refresh(),
          child: _AskBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navyDark,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AskCreateSheet(),
    );
  }
}

// ── Shared Ask feed body ───────────────────────────────────────────────────────

class _AskBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(askFeedProvider);
    final l = AppLocalizations.of(context);

    if (state.isLoading && state.posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    if (state.posts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 80),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.askEmptyTitle,
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark ? AppColors.white : AppColors.navyDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.askEmptySubtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240 &&
            !state.isLoadingMore &&
            state.hasMore &&
            state.posts.isNotEmpty) {
          ref.read(askFeedProvider.notifier).loadOlder();
        }
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () => ref.read(askFeedProvider.notifier).refresh(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: state.posts.length + 1,
          itemBuilder: (context, i) {
            if (i == state.posts.length) {
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        strokeWidth: 2.4,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox(height: 80);
            }
            return AskPostCard(post: state.posts[i]);
          },
        ),
      ),
    );
  }
}
