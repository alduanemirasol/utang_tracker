import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/features/backup/data/services/backup_prefs_service.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_prefs_repository.dart';

class BackupPrefsRepositoryImpl implements BackupPrefsRepository {
  BackupPrefsRepositoryImpl({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> _getPrefs() async => _prefsOverride ?? await SharedPreferences.getInstance();

  Future<BackupPrefsService> _service() async => BackupPrefsService(await _getPrefs());

  @override
  Future<BackupInterval> getInterval() async => (await _service()).interval;

  @override
  Future<void> setInterval(BackupInterval interval) async => (await _service()).setInterval(interval);

  @override
  Future<DateTime?> getLastSuccessful() async => (await _service()).lastSuccessfulUtc;

  @override
  Future<DateTime?> getNextScheduled() async => (await _service()).nextScheduledUtc;

  @override
  Future<String?> getLastError() async => (await _service()).lastError;

  @override
  Future<void> setLastError(String? message) async => (await _service()).setLastError(message);

  @override
  Future<void> clearLastError() async => (await _service()).setLastError(null);

  @override
  Future<void> updateLastSuccessful(DateTime utcNow) async => (await _service()).updateLastSuccessful(utcNow);
}
