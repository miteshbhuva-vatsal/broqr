import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/services/whatsapp_webhook_service.dart';
import 'package:cpapp/features/crm/data/models/lead_model.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/domain/entities/lead_activity.dart';

abstract interface class CrmRemoteDataSource {
  Future<List<LeadModel>> fetchLeads(String ownerUid);

  /// Live stream of the most recent [limit] leads, ordered by updatedAt desc.
  /// Older pages are fetched on demand via [fetchOlderLeads].
  Stream<List<LeadModel>> watchRecentLeads(
    String ownerUid, {
    int limit = 30,
  });

  /// One-shot fetch of leads strictly older than [beforeUpdatedAt], ordered
  /// updatedAt desc. Used for pagination after the streamed page.
  Future<List<LeadModel>> fetchOlderLeads({
    required String ownerUid,
    required DateTime beforeUpdatedAt,
    int limit = 30,
  });

  /// Live stream of the most recent org-wide leads (Admin) or own-team leads
  /// (Manager). Filtered client-side by [teamIds] when non-empty.
  Stream<List<LeadModel>> watchRecentOrgLeads(
    String orgId, {
    int limit = 50,
  });

  Future<List<LeadModel>> fetchOlderOrgLeads({
    required String orgId,
    required DateTime beforeUpdatedAt,
    int limit = 50,
  });

  Future<LeadModel> createLead({
    required String ownerUid,
    required String clientName,
    required LeadStage stage,
    required LeadPriority priority,
    String? clientPhone,
    double? estimatedValue,
    String? linkedListingId,
    String? linkedListingCity,
    String? linkedListingPrice,
    String? linkedListingImageUrl,
    String? remarks,
    LeadSource source = LeadSource.added,
    String? orgId,
    String? teamId,
    String? assignedTo,
  });

  /// Auto-creates a "contacted" lead for the listing owner when an interested
  /// user taps Contact, AND increments listings/{id}.contactsCount in the same
  /// batch. Skips creation if the same (broker, listing, phone) lead already
  /// exists. Returns whether a lead was actually created.
  Future<ContactLeadOutcome> createContactLead({
    required String brokerUid,
    required String clientName,
    required String? clientPhone,
    required String listingId,
    required String? listingCity,
    required String? listingPriceLabel,
  });

  Future<LeadModel> updateLead({
    required String leadId,
    String? clientName,
    String? clientPhone,
    LeadStage? stage,
    LeadPriority? priority,
    double? estimatedValue,
    bool clearEstimatedValue = false,
    String? teamId,
    bool clearTeamId = false,
    String? assignedTo,
    bool clearAssignedTo = false,
    int? visitCount,
  });

  Future<LeadModel> addNote({
    required String leadId,
    required String text,
  });

  Future<LeadModel> deleteNote({
    required String leadId,
    required String noteId,
  });

  Future<LeadModel> setReminder({
    required String leadId,
    DateTime? reminderAt,
    String? reminderNote,
  });

  Future<void> deleteLead(String leadId);

  Stream<List<LeadActivity>> watchActivity(String leadId);
  Future<void> addActivity({
    required String leadId,
    required LeadActivityType type,
    required String description,
    String? actorName,
    Map<String, dynamic>? metadata,
    int? leadScore,
  });
}

class CrmRemoteDataSourceImpl implements CrmRemoteDataSource {
  const CrmRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _leads =>
      _db.collection(AppConstants.leadsCollection);

  @override
  Future<List<LeadModel>> fetchLeads(String ownerUid) async {
    try {
      final snap = await _leads
          .where('ownerUid', isEqualTo: ownerUid)
          .orderBy('updatedAt', descending: true)
          .limit(30)
          .get();
      return snap.docs.map((d) => LeadModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch leads: $e');
    }
  }

  @override
  Stream<List<LeadModel>> watchRecentLeads(
    String ownerUid, {
    int limit = 30,
  }) {
    return _leads
        .where('ownerUid', isEqualTo: ownerUid)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => LeadModel.fromFirestore(d)).toList(),
        );
  }

  @override
  Future<List<LeadModel>> fetchOlderLeads({
    required String ownerUid,
    required DateTime beforeUpdatedAt,
    int limit = 30,
  }) async {
    try {
      // Single-field cursor — server timestamps have microsecond precision so
      // collisions are vanishingly rare. State-level dedup by lead id absorbs
      // any boundary overlap.
      final snap = await _leads
          .where('ownerUid', isEqualTo: ownerUid)
          .orderBy('updatedAt', descending: true)
          .startAfter([Timestamp.fromDate(beforeUpdatedAt)])
          .limit(limit)
          .get();
      return snap.docs.map((d) => LeadModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch older leads: $e');
    }
  }

  @override
  Future<LeadModel> createLead({
    required String ownerUid,
    required String clientName,
    required LeadStage stage,
    required LeadPriority priority,
    String? clientPhone,
    double? estimatedValue,
    String? linkedListingId,
    String? linkedListingCity,
    String? linkedListingPrice,
    String? linkedListingImageUrl,
    String? remarks,
    LeadSource source = LeadSource.added,
    String? orgId,
    String? teamId,
    String? assignedTo,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();
      final model = LeadModel(
        id: id,
        ownerUid: ownerUid,
        clientName: clientName,
        clientPhone: clientPhone,
        stage: stage,
        priority: priority,
        estimatedValue: estimatedValue,
        linkedListingId: linkedListingId,
        linkedListingCity: linkedListingCity,
        linkedListingPrice: linkedListingPrice,
        linkedListingImageUrl: linkedListingImageUrl,
        remarks: remarks,
        source: source,
        createdAt: now,
        updatedAt: now,
        orgId: orgId,
        teamId: teamId,
        assignedTo: assignedTo,
      );
      await _leads.doc(id).set(model.toMap());
      WhatsAppWebhookService.notifyLeadCreated(
        clientName: clientName,
        clientPhone: clientPhone,
        stage: stage.firestoreKey,
        priority: priority.name,
        linkedListingCity: linkedListingCity,
        linkedListingPrice: linkedListingPrice,
      );
      return model;
    } catch (e) {
      throw ServerException('Failed to create lead: $e');
    }
  }

  @override
  Future<ContactLeadOutcome> createContactLead({
    required String brokerUid,
    required String clientName,
    required String? clientPhone,
    required String listingId,
    required String? listingCity,
    required String? listingPriceLabel,
  }) async {
    try {
      // Dedup: same (broker, listing, phone) → skip create.
      // Phone is required for the dedup key; if missing we still create.
      // The query targets the broker's leads; if the caller isn't the broker,
      // Firestore denies it — treat that as "no duplicate" and proceed.
      if (clientPhone != null && clientPhone.isNotEmpty) {
        try {
          final existing = await _leads
              .where('ownerUid', isEqualTo: brokerUid)
              .where('linkedListingId', isEqualTo: listingId)
              .where('clientPhone', isEqualTo: clientPhone)
              .limit(1)
              .get();
          if (existing.docs.isNotEmpty) {
            return ContactLeadOutcome.alreadyExisted;
          }
        } catch (_) {
          // Dedup check denied (caller is not the broker) — proceed with create.
        }
      }

      // Fetch broker's orgId so the lead is visible in the broker's CRM.
      // Team-plan brokers watch leads by orgId; without this field the contact
      // lead would be invisible to them even though ownerUid matches.
      String? brokerOrgId;
      try {
        final brokerDoc = await _db
            .collection(AppConstants.usersCollection)
            .doc(brokerUid)
            .get();
        final data = brokerDoc.data();
        if (data != null && data['orgId'] is String) {
          brokerOrgId = data['orgId'] as String;
        }
      } catch (_) {
        // Non-fatal: proceed without orgId; individual-plan brokers work fine.
      }

      final callerUid = FirebaseAuth.instance.currentUser?.uid;

      final batch = _db.batch();
      final leadRef = _leads.doc();
      batch.set(leadRef, {
        'ownerUid': brokerUid,
        if (brokerOrgId != null) 'orgId': brokerOrgId,
        'clientName': clientName,
        'clientPhone': (clientPhone != null && clientPhone.isNotEmpty)
            ? clientPhone
            : null,
        'stage': LeadStage.newLead.firestoreKey,
        'priority': LeadPriority.medium.name,
        'source': LeadSource.contacted.name,
        'linkedListingId': listingId,
        'linkedListingCity': listingCity,
        'linkedListingPrice': listingPriceLabel,
        'notes': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final listingRef =
          _db.collection(AppConstants.listingsCollection).doc(listingId);
      batch.update(listingRef, {'contactsCount': FieldValue.increment(1)});
      // Record inquiry atomically so the caller's feed shows "Inquired" state.
      if (callerUid != null) {
        batch.set(
          _db
              .collection(AppConstants.usersCollection)
              .doc(callerUid)
              .collection('inquiries')
              .doc(listingId),
          {'inquiredAt': FieldValue.serverTimestamp()},
        );
      }
      await batch.commit();
      return ContactLeadOutcome.created;
    } catch (e) {
      throw ServerException('Failed to record contact: $e');
    }
  }

  @override
  Future<LeadModel> updateLead({
    required String leadId,
    String? clientName,
    String? clientPhone,
    LeadStage? stage,
    LeadPriority? priority,
    double? estimatedValue,
    bool clearEstimatedValue = false,
    String? teamId,
    bool clearTeamId = false,
    String? assignedTo,
    bool clearAssignedTo = false,
    int? visitCount,
  }) async {
    try {
      final now = DateTime.now();
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (clientName != null) updates['clientName'] = clientName;
      if (clientPhone != null) updates['clientPhone'] = clientPhone;
      if (stage != null) updates['stage'] = stage.firestoreKey;
      if (priority != null) updates['priority'] = priority.name;
      if (clearEstimatedValue) {
        updates['estimatedValue'] = null;
      } else if (estimatedValue != null) {
        updates['estimatedValue'] = estimatedValue;
      }
      if (clearTeamId) {
        updates['teamId'] = null;
      } else if (teamId != null) {
        updates['teamId'] = teamId;
      }
      if (clearAssignedTo) {
        updates['assignedTo'] = null;
      } else if (assignedTo != null) {
        updates['assignedTo'] = assignedTo;
      }
      if (visitCount != null) updates['visitCount'] = visitCount;

      LeadStage? priorStage;
      final updated = await _db.runTransaction((tx) async {
        final ref = _leads.doc(leadId);
        final snap = await tx.get(ref);
        final current = LeadModel.fromFirestore(snap);
        priorStage = current.stage;
        tx.update(ref, updates);
        return LeadModel(
          id: current.id,
          ownerUid: current.ownerUid,
          clientName: clientName ?? current.clientName,
          clientPhone: clientPhone ?? current.clientPhone,
          stage: stage ?? current.stage,
          priority: priority ?? current.priority,
          estimatedValue: clearEstimatedValue
              ? null
              : (estimatedValue ?? current.estimatedValue),
          linkedListingId: current.linkedListingId,
          linkedListingCity: current.linkedListingCity,
          linkedListingPrice: current.linkedListingPrice,
          linkedListingImageUrl: current.linkedListingImageUrl,
          notes: current.notes,
          createdAt: current.createdAt,
          updatedAt: now,
          reminderAt: current.reminderAt,
          reminderNote: current.reminderNote,
          remarks: current.remarks,
          source: current.source,
          orgId: current.orgId,
          teamId: clearTeamId ? null : (teamId ?? current.teamId),
          assignedTo:
              clearAssignedTo ? null : (assignedTo ?? current.assignedTo),
          visitCount: visitCount ?? current.visitCount,
        );
      });
      if (stage != null && priorStage != null && priorStage != stage) {
        WhatsAppWebhookService.notifyStageChanged(
          clientName: updated.clientName,
          clientPhone: updated.clientPhone,
          oldStage: priorStage!.firestoreKey,
          newStage: stage.firestoreKey,
        );
      }
      return updated;
    } catch (e) {
      throw ServerException('Failed to update lead: $e');
    }
  }

  @override
  Future<LeadModel> addNote({
    required String leadId,
    required String text,
  }) async {
    try {
      final note = LeadNote(
        id: const Uuid().v4(),
        text: text.trim(),
        createdAt: DateTime.now(),
      );
      final ref = _leads.doc(leadId);
      // arrayUnion is concurrent-safe; transactional read+rewrite would lose
      // notes added by other writers between read and commit.
      await ref.update({
        'notes': FieldValue.arrayUnion([note.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final snap = await ref.get();
      return LeadModel.fromFirestore(snap);
    } catch (e) {
      throw ServerException('Failed to add note: $e');
    }
  }

  @override
  Future<LeadModel> deleteNote({
    required String leadId,
    required String noteId,
  }) async {
    try {
      return await _db.runTransaction((tx) async {
        final ref = _leads.doc(leadId);
        final snap = await tx.get(ref);
        final current = LeadModel.fromFirestore(snap);
        final updatedNotes =
            current.notes.where((n) => n.id != noteId).toList();
        tx.update(ref, {
          'notes': updatedNotes.map((n) => n.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return LeadModel(
          id: current.id,
          ownerUid: current.ownerUid,
          clientName: current.clientName,
          clientPhone: current.clientPhone,
          stage: current.stage,
          priority: current.priority,
          estimatedValue: current.estimatedValue,
          linkedListingId: current.linkedListingId,
          linkedListingCity: current.linkedListingCity,
          linkedListingPrice: current.linkedListingPrice,
          linkedListingImageUrl: current.linkedListingImageUrl,
          notes: updatedNotes,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          reminderAt: current.reminderAt,
          reminderNote: current.reminderNote,
          source: current.source,
          orgId: current.orgId,
          teamId: current.teamId,
          assignedTo: current.assignedTo,
        );
      });
    } catch (e) {
      throw ServerException('Failed to delete note: $e');
    }
  }

  @override
  Future<LeadModel> setReminder({
    required String leadId,
    DateTime? reminderAt,
    String? reminderNote,
  }) async {
    try {
      return await _db.runTransaction((tx) async {
        final ref = _leads.doc(leadId);
        final snap = await tx.get(ref);
        final current = LeadModel.fromFirestore(snap);
        tx.update(ref, {
          'reminderAt':
              reminderAt != null ? Timestamp.fromDate(reminderAt) : null,
          'reminderNote': reminderNote,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return LeadModel(
          id: current.id,
          ownerUid: current.ownerUid,
          clientName: current.clientName,
          clientPhone: current.clientPhone,
          stage: current.stage,
          priority: current.priority,
          estimatedValue: current.estimatedValue,
          linkedListingId: current.linkedListingId,
          linkedListingCity: current.linkedListingCity,
          linkedListingPrice: current.linkedListingPrice,
          linkedListingImageUrl: current.linkedListingImageUrl,
          notes: current.notes,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          reminderAt: reminderAt,
          reminderNote: reminderNote,
          source: current.source,
          orgId: current.orgId,
          teamId: current.teamId,
          assignedTo: current.assignedTo,
        );
      });
    } catch (e) {
      throw ServerException('Failed to set reminder: $e');
    }
  }

  @override
  Future<void> deleteLead(String leadId) async {
    try {
      await _leads.doc(leadId).delete();
    } catch (e) {
      throw ServerException('Failed to delete lead: $e');
    }
  }

  @override
  Stream<List<LeadActivity>> watchActivity(String leadId) {
    return _leads
        .doc(leadId)
        .collection(AppConstants.leadActivitySubcollection)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return LeadActivity(
              id: d.id,
              type: LeadActivityType.fromString(data['type'] as String?),
              description: (data['description'] as String?) ?? '',
              actorName: data['actorName'] as String?,
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }).toList(),
        );
  }

  @override
  Future<void> addActivity({
    required String leadId,
    required LeadActivityType type,
    required String description,
    String? actorName,
    Map<String, dynamic>? metadata,
    int? leadScore,
  }) async {
    try {
      final batch = _db.batch();
      final activityRef = _leads
          .doc(leadId)
          .collection(AppConstants.leadActivitySubcollection)
          .doc();
      batch.set(activityRef, {
        'type': type.firestoreKey,
        'description': description,
        if (actorName != null && actorName.isNotEmpty) 'actorName': actorName,
        if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_leads.doc(leadId), {
        'touchpointCount': FieldValue.increment(1),
        'lastActivityAt': FieldValue.serverTimestamp(),
        if (leadScore != null) 'leadScore': leadScore,
      });
      await batch.commit();
    } catch (_) {
      // Fire-and-forget; swallow errors so the main action is never blocked.
    }
  }

  // ── Org-scoped queries ────────────────────────────────────────────────────

  @override
  Stream<List<LeadModel>> watchRecentOrgLeads(
    String orgId, {
    int limit = 50,
  }) {
    return _leads
        .where('orgId', isEqualTo: orgId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(LeadModel.fromFirestore).toList());
  }

  @override
  Future<List<LeadModel>> fetchOlderOrgLeads({
    required String orgId,
    required DateTime beforeUpdatedAt,
    int limit = 50,
  }) async {
    try {
      final snap = await _leads
          .where('orgId', isEqualTo: orgId)
          .orderBy('updatedAt', descending: true)
          .startAfter([Timestamp.fromDate(beforeUpdatedAt)])
          .limit(limit)
          .get();
      return snap.docs.map(LeadModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException('Failed to fetch older org leads: $e');
    }
  }
}
