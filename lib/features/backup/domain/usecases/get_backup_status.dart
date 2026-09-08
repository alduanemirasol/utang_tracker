import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_prefs_repository.dart';

class GetBackupStatus {
  const GetBackupStatus(this._prefs);

  final BackupPrefsRepository _prefs;

  Future<BackupInterval> getInterval() => _prefs.getInterval();

  Future<void> setInterval(BackupInterval interval) => _prefs.setInterval(interval);

  Future<DateTime?> getLastSuccessful() => _prefs.getLastSuccessful();

  Future<DateTime?> getNextScheduled() => _prefs.getNextScheduled();

  Future<String?> getLastError() => _prefs.getLastError();

  Future<void> clearLastError() => _prefs.clearLastError();
}
