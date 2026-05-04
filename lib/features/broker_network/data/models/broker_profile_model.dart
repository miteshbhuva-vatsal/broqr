import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/broker_network/domain/entities/broker_profile.dart';

class BrokerProfileModel extends BrokerProfile {
  const BrokerProfileModel({
    required super.uid,
    required super.name,
    required super.createdAt,
    super.photoUrl,
    super.city,
    super.reraNumber,
    super.isVerified,
    super.listingsCount,
    super.connectionsCount,
  });

  factory BrokerProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return BrokerProfileModel(
      uid: doc.id,
      name: d['name'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      city: d['city'] as String?,
      reraNumber: d['reraNumber'] as String?,
      isVerified: d['isVerified'] as bool? ?? false,
      listingsCount: d['listingsCount'] as int? ?? 0,
      connectionsCount: d['connectionsCount'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
