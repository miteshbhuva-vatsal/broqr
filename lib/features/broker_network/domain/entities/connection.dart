import 'package:equatable/equatable.dart';

enum ConnectionStatus { none, following }

class Connection extends Equatable {
  const Connection({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  /// Deterministic document ID — sorted UIDs joined with '_'.
  static String idFor(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Returns the uid of the other participant.
  String otherUid(String myUid) =>
      followerId == myUid ? followingId : followerId;

  ConnectionStatus statusFor(String myUid) {
    if (followerId == myUid || followingId == myUid) {
      return ConnectionStatus.following;
    }
    return ConnectionStatus.none;
  }

  @override
  List<Object?> get props => [id, followerId, followingId];
}
