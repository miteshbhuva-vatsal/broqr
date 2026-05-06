import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cpapp/core/constants/route_constants.dart';
import 'package:cpapp/core/l10n/app_localizations.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';
import 'package:cpapp/features/broker_network/presentation/providers/network_providers.dart';
import 'package:cpapp/features/broker_network/presentation/widgets/broker_card.dart';

const _navy = Color(0xFF0A1628);
const _gold = Color(0xFFD4A843);

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(networkProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NetworkState>(networkProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red[700],
          ),
        );
        ref.read(networkProvider.notifier).clearError();
      }
    });

    final tab = ref.watch(networkProvider.select((s) => s.tab));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context).networkTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _TabBar(
            selected: tab,
            onTap: (t) => ref.read(networkProvider.notifier).setTab(t),
          ),
        ),
      ),
      body: tab == NetworkTab.discover
          ? _DiscoverTab(scrollController: _scrollController)
          : const _ConnectionsTab(),
    );
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────

class _TabBar extends ConsumerWidget {
  const _TabBar({required this.selected, required this.onTap});
  final NetworkTab selected;
  final ValueChanged<NetworkTab> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Container(
      color: _navy,
      child: Row(
        children: [
          _Tab(
            label: l.discover,
            isSelected: selected == NetworkTab.discover,
            onTap: () => onTap(NetworkTab.discover),
          ),
          _Tab(
            label: l.following,
            isSelected: selected == NetworkTab.connections,
            onTap: () => onTap(NetworkTab.connections),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _gold : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _gold : Colors.white60,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Discover tab ──────────────────────────────────────────────────────────────

class _DiscoverTab extends ConsumerWidget {
  const _DiscoverTab({required this.scrollController});
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }

    if (state.brokers.isEmpty) {
      final l = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              l.noBrokersFound,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _navy,
      onRefresh: () => ref.read(networkProvider.notifier).refresh(),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.brokers.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.brokers.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: _navy),
              ),
            );
          }

          final broker = state.brokers[index];
          final connectionId = _connectionIdFor(broker.uid, state);

          return GestureDetector(
            onTap: () => context.push(
              Routes.brokerProfile.replaceFirst(':brokerId', broker.uid),
            ),
            child: BrokerCard(
              broker: broker,
              connectionId: connectionId,
            ),
          );
        },
      ),
    );
  }

  String? _connectionIdFor(String uid, NetworkState state) {
    for (final c in state.connections) {
      if (c.followerId == uid || c.followingId == uid) return c.id;
    }
    return null;
  }
}

// ── Connections tab ───────────────────────────────────────────────────────────

class _ConnectionsTab extends ConsumerWidget {
  const _ConnectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: _navy));
    }

    final following = state.connections;

    if (following.isEmpty) {
      final l = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              l.noFollowingYet,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              l.discoverAndFollow,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final myUid =
        ref.read(authStateChangesProvider).valueOrNull?.uid ?? '';

    return RefreshIndicator(
      color: _navy,
      onRefresh: () => ref.read(networkProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          _SectionHeader(title: AppLocalizations.of(context).followingHeader),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ConnectionTile(
                connection: following[i],
                myUid: myUid,
                brokers: state.brokers,
                onTap: (uid) => context.push(
                  Routes.brokerProfile.replaceFirst(':brokerId', uid),
                ),
              ),
              childCount: following.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.connection,
    required this.myUid,
    required this.brokers,
    required this.onTap,
  });

  final Connection connection;
  final String myUid;
  final List<BrokerProfile> brokers;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final otherUid = connection.otherUid(myUid);
    final matches = brokers.where((b) => b.uid == otherUid).toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    final broker = matches.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onTap(otherUid),
          child: BrokerCard(
            broker: broker,
            connectionId: connection.id,
          ),
        ),
        if (true)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push(
                    Routes.chatDetail.replaceFirst(':chatId', connection.id),
                    extra: {
                      'otherName': broker.name,
                      'otherPhoto': broker.photoUrl,
                    },
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: const BorderSide(color: _gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
