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
    super.linkedListingImageUrl,
    super.notes,
    super.reminderAt,
    super.reminderNote,
    super.remarks,
    super.source,
    super.orgId,
    super.teamId,
    super.assignedTo,
    super.leadScore,
    super.touchpointCount,
    super.lastActivityAt,
    super.visitCount,
  });

  factory LeadModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final rawNotes = d['notes'] as List<dynamic>? ?? [];
    return LeadModel(
      id: doc.id,
      ownerUid: (d['ownerUid'] as String?) ?? '',
      clientName: d['clientName'] as String? ?? '',
      clientPhone: d['clientPhone'] as String?,
      stage: LeadStage.fromString(d['stage'] as String?),
      priority: LeadPriority.fromString(d['priority'] as String?),
      estimatedValue: (d['estimatedValue'] as num?)?.toDouble(),
      linkedListingId: d['linkedListingId'] as String?,
      linkedListingCity: d['linkedListingCity'] as String?,
      linkedListingPrice: d['linkedListingPrice'] as String?,
      linkedListingImageUrl: d['linkedListingImageUrl'] as String?,
      notes: rawNotes.map((n) {
        final m = Map<String, dynamic>.from(n as Map<String, dynamic>);
        if (m['createdAt'] is Timestamp) {
          m['createdAt'] =
              (m['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return LeadNote.fromMap(m);
      }).toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reminderAt: (d['reminderAt'] as Timestamp?)?.toDate(),
      reminderNote: d['reminderNote'] as String?,
      remarks: d['remarks'] as String?,
      source: LeadSource.fromString(d['source'] as String?),
      orgId: d['orgId'] as String?,
      teamId: d['teamId'] as String?,
      assignedTo: d['assignedTo'] as String?,
      leadScore: (d['leadScore'] as num?)?.toInt() ?? 0,
      touchpointCount: (d['touchpointCount'] as num?)?.toInt() ?? 0,
      lastActivityAt: (d['lastActivityAt'] as Timestamp?)?.toDate(),
      visitCount: (d['visitCount'] as num?)?.toInt() ?? 0,
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
        'linkedListingImageUrl': linkedListingImageUrl,
        'notes': notes.map((n) => n.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
        'reminderAt':
            reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
        'reminderNote': reminderNote,
        'remarks': remarks,
        'source': source.name,
        'orgId': orgId,
        'teamId': teamId,
        'assignedTo': assignedTo,
        'leadScore': leadScore,
        'touchpointCount': touchpointCount,
        if (lastActivityAt != null)
          'lastActivityAt': Timestamp.fromDate(lastActivityAt!),
        'visitCount': visitCount,
      };
}
