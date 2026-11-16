/// Abstract base class for domain failures across Otto.
sealed class Failure {
  final String message;
  final int? statusCode;
  final Object? cause;

  const Failure(this.message, {this.statusCode, this.cause});

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode, super.cause});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.statusCode, super.cause});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode, super.cause});
}

class GitConflictFailure extends Failure {
  final List<String> conflictingFiles;
  const GitConflictFailure(
    super.message, {
    this.conflictingFiles = const [],
    super.statusCode,
    super.cause,
  });
}

class GuardrailViolationFailure extends Failure {
  final List<String> violations;
  const GuardrailViolationFailure(
    super.message, {
    this.violations = const [],
    super.statusCode,
    super.cause,
  });
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.statusCode, super.cause});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.statusCode, super.cause});
}
