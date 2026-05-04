/// Data-layer exceptions — converted to [Failure]s in repositories.
class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection.']);
  final String message;
}

class AuthException implements Exception {
  const AuthException([this.message = 'Authentication failed.']);
  final String message;
}

class ServerException implements Exception {
  const ServerException([this.message = 'Server error.']);
  final String message;
}

class StorageException implements Exception {
  const StorageException([this.message = 'Storage operation failed.']);
  final String message;
}

class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Not found.']);
  final String message;
}

class PermissionException implements Exception {
  const PermissionException([this.message = 'Permission denied.']);
  final String message;
}
