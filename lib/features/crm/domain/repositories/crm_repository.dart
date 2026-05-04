import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';

abstract interface class CrmRepository {
  Future<Either<Failure, List<Lead>>> fetchLeads(String ownerUid);

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
  });

  Future<Either<Failure, Lead>> updateLead({
    required String leadId,
    String? clientName,
    String? clientPhone,
    LeadStage? stage,
    LeadPriority? priority,
    double? estimatedValue,
    bool clearEstimatedValue = false,
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
}
