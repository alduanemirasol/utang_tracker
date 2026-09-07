import 'package:utang_tracker/core/error/app_exception.dart';

class BackupErrorMapper {
  BackupErrorMapper._();

  static String toTaglish(Object error) {
    if (error is NetworkException) {
      return 'Walang internet. Na-queue ang backup, susubukan ulit mamaya.';
    }
    if (error is AuthExpiredException) {
      return 'Expired ang Google sign-in. Mag-sign in ulit para mag-backup.';
    }
    if (error is QuotaExceededException) {
      return 'Puno na ang Google Drive. Magbura ng lumang backup para magkasya.';
    }
    if (error is IntegrityException) {
      return 'Sira ang backup file. Hindi ma-verify ang integridad.';
    }
    if (error is DuplicateBackupException) {
      return 'May kaparehong backup na. Na-skip ang pag-upload para iwas duplicate.';
    }
    if (error is NotFoundException) {
      return 'Hindi makita ang backup file sa Drive.';
    }
    if (error is ValidationException) {
      return 'Kailangan ng confirmation bago mag-restore.';
    }
    if (error is BackupException) {
      return 'Hindi natapos ang backup: ${error.message}';
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket') || msg.contains('failed host lookup')) {
      return 'Walang internet. Na-queue ang backup, susubukan ulit mamaya.';
    }
    if (msg.contains('401') || msg.contains('auth') && msg.contains('expired')) {
      return 'Expired ang Google sign-in. Mag-sign in ulit para mag-backup.';
    }
    return 'Hindi natapos ang backup. Pakisubukan ulit: $error';
  }
}
