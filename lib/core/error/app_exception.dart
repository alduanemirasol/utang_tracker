class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

class ConflictException extends AppException {
  const ConflictException(super.message);
}

class BackupException extends AppException {
  const BackupException(super.message);
}

class AuthExpiredException extends AppException {
  const AuthExpiredException(super.message);
}

class IntegrityException extends AppException {
  const IntegrityException(super.message);
}

class QuotaExceededException extends AppException {
  const QuotaExceededException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class DuplicateBackupException extends AppException {
  const DuplicateBackupException(super.message);
}
