import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';
import 'package:cpapp/features/broker_network/domain/entities/connection.dart';
import 'package:cpapp/features/broker_network/presentation/providers/network_providers.dart';

const _navy = Color(0xFF0A1628);

class BrokerCard extends ConsumerWidget {
  const BrokerCard({
    super.key,
    required this.broker,
    required this.connectionId,
  });

  final BrokerProfile broker;

  /// Non-null when a Connection document exists for this pair.
  final String? connectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      networkProvider.select((s) => s.statusFor(broker.uid)),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Avatar(broker: broker),
            const SizedBox(width: 12),
            Expanded(child: _Info(broker: broker)),
            _ActionButton(
              broker: broker,
              connectionId: connectionId,
              status: status,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.broker});
  final BrokerProfile broker;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _navy.withValues(alpha: 0.1),
          backgroundImage: broker.photoUrl != null
              ? CachedNetworkImageProvider(broker.photoUrl!)
              : null,
          child: broker.photoUrl == null
              ? Text(
                  broker.initials,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              : null,
        ),
        if (broker.isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 14,
                color: Color(0xFF22C55E),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Info ──────────────────────────────────────────────────────────────────────

class _Info extends StatelessWidget {
  const _Info({required this.broker});
  final BrokerProfile broker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          broker.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: _navy,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (broker.city != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
              const SizedBox(width: 2),
              Text(
                broker.city!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            _Stat(
              icon: Icons.home_work_outlined,
              value: broker.listingsCount,
              label: 'listings',
            ),
            const SizedBox(width: 12),
            _Stat(
              icon: Icons.people_outline,
              value: broker.connectionsCount,
              label: 'followers',
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 2),
        Text(
          '$value $label',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends ConsumerWidget {
  const _ActionButton({
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
      return _OutlinedActionButton(
        label: 'Following',
        color: Colors.green,
        onTap: connectionId == null
            ? null
            : () => ref.read(networkProvider.notifier).unfollow(
                  connectionId: connectionId!,
                  otherUid: broker.uid,
                ),
      );
    }
    return _OutlinedActionButton(
      label: 'Follow',
      color: _navy,
      onTap: () => ref.read(networkProvider.notifier).follow(broker.uid),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(80, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
