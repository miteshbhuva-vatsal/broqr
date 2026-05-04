import 'package:dartz/dartz.dart';
import 'package:cpapp/core/errors/exceptions.dart';
import 'package:cpapp/core/errors/failures.dart';
import 'package:cpapp/features/crm/data/datasources/crm_remote_datasource.dart';
import 'package:cpapp/features/crm/domain/entities/lead.dart';
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
}
