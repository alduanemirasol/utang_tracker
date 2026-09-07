import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';

class BackupPrefsService {
  BackupPrefsService(this._prefs);

  final SharedPreferences _prefs;

  BackupInterval get interval =>
      BackupIntervalX.fromName(_prefs.getString(BackupPrefsKeys.interval));

  Future<void> setInterval(BackupInterval value) async {
    await _prefs.setString(BackupPrefsKeys.interval, value.name);
  }

  bool get autoBackupEnabled => interval != BackupInterval.off;

  DateTime? get lastSuccessfulUtc {
    final ms = _prefs.getInt(BackupPrefsKeys.lastBackupTime);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  DateTime? get nextScheduledUtc {
    final ms = _prefs.getInt(BackupPrefsKeys.nextScheduledTime);
    if (ms == null) {
      final last = lastSuccessfulUtc;
      final dur = interval.duration;
      if (last == null || dur == null) return null;
      return last.add(dur);
    }
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> updateLastSuccessful(DateTime utcNow) async {
    await _prefs.setInt(
      BackupPrefsKeys.lastBackupTime,
      utcNow.toUtc().millisecondsSinceEpoch,
    );
    final next = interval.duration == null
        ? null
        : utcNow.toUtc().add(interval.duration!);
    if (next != null) {
      await _prefs.setInt(
        BackupPrefsKeys.nextScheduledTime,
        next.millisecondsSinceEpoch,
      );
    } else {
      await _prefs.remove(BackupPrefsKeys.nextScheduledTime);
    }
  }

  String? get lastError => _prefs.getString(BackupPrefsKeys.lastError);

  Future<void> setLastError(String? message) async {
    if (message == null || message.isEmpty) {
      await _prefs.remove(BackupPrefsKeys.lastError);
    } else {
      await _prefs.setString(BackupPrefsKeys.lastError, message);
    }
  }

  String formatLocal(DateTime utcTime) {
    return DateFormatters.backupDisplay(utcTime);
  }
}
