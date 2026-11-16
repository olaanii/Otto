/// Base exception classes thrown by data sources and platform services.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  const ServerException(this.message, {this.statusCode, this.responseData});

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ClerkAuthException implements Exception {
  final String message;
  final int? statusCode;

  const ClerkAuthException(this.message, {this.statusCode});

  @override
  String toString() => 'ClerkAuthException: $message (status: $statusCode)';
}

class GitOperationException implements Exception {
  final String message;
  final List<String> conflictingFiles;

  const GitOperationException(this.message, {this.conflictingFiles = const []});

  @override
  String toString() => 'GitOperationException: $message';
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
