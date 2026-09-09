import 'package:utang_tracker/core/error/app_exception.dart';

class BackupErrorMapper {
  BackupErrorMapper._();

  static String toEnglish(Object error) {
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
      return _mapBackupException(error);
    }

    // Fallback: raw-string matching for errors that bypass typed exceptions.
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host lookup')) {
      return 'No internet connection. Backup has been queued and will be retried later.';
    }
    if (msg.contains('401') || (msg.contains('auth') && msg.contains('expired'))) {
      return 'Google sign-in expired. Please sign in again to continue backup.';
    }
    if (msg.contains('sign_in_canceled')) {
      return 'Sign-in cancelled';
    }
    if (msg.contains('developer_error') ||
        msg.contains('apicode: 10') ||
        msg.contains('apicode:10') ||
        msg.contains('apiexception: 10') ||
        msg.contains('apiexception:10') ||
        msg.contains('12500') ||
        msg.contains('invalid_account')) {
      return 'DEVELOPER_ERROR — check SHA fingerprint and google-services.json. '
          'See docs/SETUP.md §4.7.';
    }
    return 'Backup failed. Please try again: $error';
  }

  /// Maps [BackupException] instances to user-friendly English, extracting
  /// actionable guidance when the message contains known error tokens.
  static String _mapBackupException(BackupException error) {
    final msg = error.message.toLowerCase();

    // Configuration / developer errors surfaced by _handleAuthError.
    if (msg.contains('developer_error') ||
        msg.contains('apicode: 10') ||
        msg.contains('apicode:10') ||
        msg.contains('apiexception: 10') ||
        msg.contains('apiexception:10') ||
        msg.contains('12500') ||
        msg.contains('invalid_account')) {
      return 'Sign-in failed — configuration error (DEVELOPER_ERROR 10). '
          'Check SHA fingerprint and google-services.json. '
          'See docs/SETUP.md §4.7 for troubleshooting.';
    }
    // Generic sign-in failure with guidance.
    if (msg.contains('sign_in_failed')) {
      return 'Sign-in failed. The Google account may not be available on the device '
          'or the app lacks permission. Try removing and re-adding the Google account '
          'in device Settings. See docs/SETUP.md §4.7.';
    }
    // Fall back to the original message for other BackupExceptions.
    return 'Backup failed: ${error.message}';
  }

  @Deprecated('Use toEnglish instead')
  static String toTaglish(Object error) => toEnglish(error);
}
