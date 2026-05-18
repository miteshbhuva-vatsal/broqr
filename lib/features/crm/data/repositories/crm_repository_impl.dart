import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/crm/data/datasources/crm_remote_datasource.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
import 'package:cpapp/features/crm/domain/entities/lead_activity.dart';
import 'package:cpapp/features/crm/domain/repositories/crm_repository.dart';

class CrmRepositoryImpl implements CrmRepository {
  const CrmRepositoryImpl({required CrmRemoteDataSource dataSource})
      : _ds = dataSource;

  final CrmRemoteDataSource _ds;

  @override
  Future<Either<Failure, List<Lead>>> fetchLeads(String ownerUid) async {
    try {
      return Right(await _ds.fetchLeads(ownerUid));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Lead>>> fetchOlderLeads({
    required String ownerUid,
    required DateTime beforeUpdatedAt,
    int limit = 100,
  }) async {
    try {
      return Right(
        await _ds.fetchOlderLeads(
          ownerUid: ownerUid,
          beforeUpdatedAt: beforeUpdatedAt,
          limit: limit,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      return Right(
        await _ds.createLead(
          ownerUid: ownerUid,
          clientName: clientName,
          stage: stage,
          priority: priority,
          clientPhone: clientPhone,
          estimatedValue: estimatedValue,
          linkedListingId: linkedListingId,
          linkedListingCity: linkedListingCity,
          linkedListingPrice: linkedListingPrice,
          linkedListingImageUrl: linkedListingImageUrl,
          remarks: remarks,
          source: source,
          orgId: orgId,
          teamId: teamId,
          assignedTo: assignedTo,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Lead>>> fetchOlderOrgLeads({
    required String orgId,
    required DateTime beforeUpdatedAt,
    int limit = 100,
  }) async {
    try {
      return Right(await _ds.fetchOlderOrgLeads(
        orgId: orgId,
        beforeUpdatedAt: beforeUpdatedAt,
        limit: limit,
      ),);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ContactLeadOutcome>> createContactLead({
    required String brokerUid,
    required String clientName,
    required String? clientPhone,
    required String listingId,
    required String? listingCity,
    required String? listingPriceLabel,
  }) async {
    try {
      return Right(
        await _ds.createContactLead(
          brokerUid: brokerUid,
          clientName: clientName,
          clientPhone: clientPhone,
          listingId: listingId,
          listingCity: listingCity,
          listingPriceLabel: listingPriceLabel,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      return Right(
        await _ds.updateLead(
          leadId: leadId,
          clientName: clientName,
          clientPhone: clientPhone,
          stage: stage,
          priority: priority,
          estimatedValue: estimatedValue,
          clearEstimatedValue: clearEstimatedValue,
          teamId: teamId,
          clearTeamId: clearTeamId,
          assignedTo: assignedTo,
          clearAssignedTo: clearAssignedTo,
          visitCount: visitCount,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> addNote({
    required String leadId,
    required String text,
  }) async {
    try {
      return Right(await _ds.addNote(leadId: leadId, text: text));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> deleteNote({
    required String leadId,
    required String noteId,
  }) async {
    try {
      return Right(
        await _ds.deleteNote(leadId: leadId, noteId: noteId),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lead>> setReminder({
    required String leadId,
    DateTime? reminderAt,
    String? reminderNote,
  }) async {
    try {
      return Right(
        await _ds.setReminder(
          leadId: leadId,
          reminderAt: reminderAt,
          reminderNote: reminderNote,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteLead(String leadId) async {
    try {
      await _ds.deleteLead(leadId);
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Stream<List<LeadActivity>> watchActivity(String leadId) =>
      _ds.watchActivity(leadId);

  @override
  Future<void> addActivity({
    required String leadId,
    required LeadActivityType type,
    required String description,
    String? actorName,
    Map<String, dynamic>? metadata,
    int? leadScore,
  }) =>
      _ds.addActivity(
        leadId: leadId,
        type: type,
        description: description,
        actorName: actorName,
        metadata: metadata,
        leadScore: leadScore,
      );
}
