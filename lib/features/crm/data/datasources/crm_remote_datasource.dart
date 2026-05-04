import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:cpapp/core/constants/app_constants.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/features/crm/data/models/lead_model.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';

abstract interface class CrmRemoteDataSource {
  Future<List<LeadModel>> fetchLeads(String ownerUid);

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
  });

  Future<LeadModel> updateLead({
    required String leadId,
    String? clientName,
    String? clientPhone,
    LeadStage? stage,
    LeadPriority? priority,
    double? estimatedValue,
    bool clearEstimatedValue = false,
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
          .get();
      return snap.docs.map((d) => LeadModel.fromFirestore(d)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch leads: $e');
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
        createdAt: now,
        updatedAt: now,
      );
      await _leads.doc(id).set(model.toMap());
      return model;
    } catch (e) {
      throw ServerException('Failed to create lead: $e');
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
  }) async {
    try {
      final Map<String, dynamic> updates = {
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

      await _leads.doc(leadId).update(updates);
      final doc = await _leads.doc(leadId).get();
      return LeadModel.fromFirestore(doc);
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
      await _leads.doc(leadId).update({
        'notes': FieldValue.arrayUnion([note.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final doc = await _leads.doc(leadId).get();
      return LeadModel.fromFirestore(doc);
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
      // Fetch current notes, remove the one with matching id, write back
      final doc = await _leads.doc(leadId).get();
      final current = LeadModel.fromFirestore(doc);
      final updated =
          current.notes.where((n) => n.id != noteId).toList();
      await _leads.doc(leadId).update({
        'notes': updated.map((n) => n.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final fresh = await _leads.doc(leadId).get();
      return LeadModel.fromFirestore(fresh);
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
      await _leads.doc(leadId).update({
        'reminderAt': reminderAt != null
            ? Timestamp.fromDate(reminderAt)
            : null,
        'reminderNote': reminderNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final doc = await _leads.doc(leadId).get();
      return LeadModel.fromFirestore(doc);
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
}
