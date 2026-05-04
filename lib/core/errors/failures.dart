import 'package:equatable/equatable.dart';

/// Base failure class — all domain-layer errors extend this.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'File upload failed.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
