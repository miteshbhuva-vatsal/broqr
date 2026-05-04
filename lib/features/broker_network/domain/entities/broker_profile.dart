import 'package:equatable/equatable.dart';

class BrokerProfile extends Equatable {
  const BrokerProfile({
    required this.uid,
    required this.name,
    required this.createdAt,
    this.photoUrl,
    this.city,
    this.reraNumber,
    this.isVerified = false,
    this.listingsCount = 0,
    this.connectionsCount = 0,
  });

  final String uid;
  final String name;
  final String? photoUrl;
  final String? city;
  final String? reraNumber;
  final bool isVerified;
  final int listingsCount;
  final int connectionsCount;
  final DateTime createdAt;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'B';
  }

  @override
  List<Object?> get props => [uid, name, city, isVerified];
}
