import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';

abstract class BackupPrefsRepository {
  Future<BackupInterval> getInterval();
  Future<void> setInterval(BackupInterval interval);
  Future<DateTime?> getLastSuccessful();
  Future<DateTime?> getNextScheduled();
  Future<String?> getLastError();
  Future<void> setLastError(String? message);
  Future<void> clearLastError();
  Future<void> updateLastSuccessful(DateTime utcNow);
  String formatLocal(DateTime utcTime);
}
