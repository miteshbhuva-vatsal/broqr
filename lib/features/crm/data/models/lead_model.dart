import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';

class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.ownerUid,
    required super.clientName,
    required super.stage,
    required super.priority,
    required super.createdAt,
    required super.updatedAt,
    super.clientPhone,
    super.estimatedValue,
    super.linkedListingId,
    super.linkedListingCity,
    super.linkedListingPrice,
    super.notes,
    super.reminderAt,
    super.reminderNote,
  });

  factory LeadModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    final rawNotes = d['notes'] as List<dynamic>? ?? [];
    return LeadModel(
      id: doc.id,
      ownerUid: d['ownerUid'] as String,
      clientName: d['clientName'] as String? ?? '',
      clientPhone: d['clientPhone'] as String?,
      stage: LeadStage.fromString(d['stage'] as String?),
      priority: LeadPriority.fromString(d['priority'] as String?),
      estimatedValue: (d['estimatedValue'] as num?)?.toDouble(),
      linkedListingId: d['linkedListingId'] as String?,
      linkedListingCity: d['linkedListingCity'] as String?,
      linkedListingPrice: d['linkedListingPrice'] as String?,
      notes: rawNotes.map((n) {
          final m = Map<String, dynamic>.from(n as Map<String, dynamic>);
          if (m['createdAt'] is Timestamp) {
            m['createdAt'] = (m['createdAt'] as Timestamp).toDate().toIso8601String();
          }
          return LeadNote.fromMap(m);
        }).toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reminderAt: (d['reminderAt'] as Timestamp?)?.toDate(),
      reminderNote: d['reminderNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'stage': stage.firestoreKey,
        'priority': priority.name,
        'estimatedValue': estimatedValue,
        'linkedListingId': linkedListingId,
        'linkedListingCity': linkedListingCity,
        'linkedListingPrice': linkedListingPrice,
        'notes': notes.map((n) => n.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'reminderAt': reminderAt != null
            ? Timestamp.fromDate(reminderAt!)
            : null,
        'reminderNote': reminderNote,
      };
}
