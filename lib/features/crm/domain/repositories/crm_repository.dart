import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/domain/entities/lead_activity.dart';

abstract interface class CrmRepository {
  Future<Either<Failure, List<Lead>>> fetchLeads(String ownerUid);

  /// One-shot pagination cursor for leads strictly older than [beforeUpdatedAt].
  Future<Either<Failure, List<Lead>>> fetchOlderLeads({
    required String ownerUid,
    required DateTime beforeUpdatedAt,
    int limit = 100,
  });

  Future<Either<Failure, Lead>> createLead({
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

  Future<Either<Failure, List<Lead>>> fetchOlderOrgLeads({
    required String orgId,
    required DateTime beforeUpdatedAt,
    int limit = 100,
  });

  /// Auto-creates a contact-source lead for the listing owner and bumps the
  /// listing's contactsCount in one batch. Idempotent on (broker, listing,
  /// phone): a repeat contact returns [ContactLeadOutcome.alreadyExisted]
  /// without writing anything.
  Future<Either<Failure, ContactLeadOutcome>> createContactLead({
    required String brokerUid,
    required String clientName,
    required String? clientPhone,
    required String listingId,
    required String? listingCity,
    required String? listingPriceLabel,
  });

  Future<Either<Failure, Lead>> updateLead({
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

  Future<Either<Failure, Lead>> addNote({
    required String leadId,
    required String text,
  });

  Future<Either<Failure, Lead>> deleteNote({
    required String leadId,
    required String noteId,
  });

  Future<Either<Failure, Lead>> setReminder({
    required String leadId,
    DateTime? reminderAt,
    String? reminderNote,
  });

  Future<Either<Failure, Unit>> deleteLead(String leadId);

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
