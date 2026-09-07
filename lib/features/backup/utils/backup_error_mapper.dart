import 'package:utang_tracker/core/error/app_exception.dart';

class BackupErrorMapper {
  BackupErrorMapper._();

  static String toTaglish(Object error) {
    if (error is NetworkException) {
      return 'No internet connection. Backup has been queued and will be retried later.';
    }
    if (error is AuthExpiredException) {
      return 'Google sign-in expired. Please sign in again to continue backup.';
    }
    if (error is QuotaExceededException) {
      return 'Google Drive is full. Delete old backups to free up space.';
    }
    if (error is IntegrityException) {
      return 'Backup file is corrupted. Integrity could not be verified.';
    }
    if (error is DuplicateBackupException) {
      return 'A duplicate backup already exists. Upload skipped to avoid duplication.';
    }
    if (error is NotFoundException) {
      return 'Backup file not found on Drive.';
    }
    if (error is ValidationException) {
      return 'Confirmation is required before restoring.';
    }
    if (error is BackupException) {
      return 'Backup failed: ${error.message}';
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host lookup')) {
      return 'No internet connection. Backup has been queued and will be retried later.';
    }
    if (msg.contains('401') || msg.contains('auth') && msg.contains('expired')) {
      return 'Google sign-in expired. Please sign in again to continue backup.';
    }
    return 'Backup failed. Please try again: $error';
  }
}
