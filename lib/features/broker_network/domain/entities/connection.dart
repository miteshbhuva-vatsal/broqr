import 'package:equatable/equatable.dart';

/// Status of a connection from the perspective of the *current* user.
enum ConnectionStatus { none, pendingSent, pendingReceived, connected }

class Connection extends Equatable {
  const Connection({
    required this.id,
    required this.senderId,
    required this.participants,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final List<String> participants;

  /// Raw Firestore status: 'pending' | 'connected'
  final String status;

  final DateTime createdAt;

  bool get isConnected => status == 'connected';
  bool get isPending => status == 'pending';

  /// Returns the uid of the *other* participant.
  String otherUid(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => '');

  /// Interprets connection status from current user's perspective.
  ConnectionStatus statusFor(String myUid) {
    if (status == 'connected') return ConnectionStatus.connected;
    if (senderId == myUid) return ConnectionStatus.pendingSent;
    return ConnectionStatus.pendingReceived;
  }

  /// Deterministic document ID — sorted UIDs joined with '_'.
  static String idFor(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  List<Object?> get props => [id, senderId, status];
}
