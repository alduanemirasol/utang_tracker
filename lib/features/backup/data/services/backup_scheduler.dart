import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_drive_service.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_local_datasource.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_queue_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_action.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_log_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_history_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_source.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:utang_tracker/core/database/database_location.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final intervalName = prefs.getString(BackupPrefsKeys.interval) ?? BackupInterval.off.name;
      final interval = BackupIntervalX.fromName(intervalName);
      if (interval == BackupInterval.off) return true;

      final auth = GoogleAuthDatasource();
      final signedIn = await auth.silentSignIn();
      if (signedIn == null) {
        final queueRaw = prefs.getString(BackupPrefsKeys.queue);
        final queue = queueRaw == null || queueRaw.isEmpty
            ? <BackupQueueEntry>[]
            : BackupQueueEntry.decodeList(queueRaw);
        if (queue.length < 20) {
          queue.add(BackupQueueEntry(type: 'auto', timestamp: DateTime.now().toUtc(), retryCount: 0));
          await prefs.setString(BackupPrefsKeys.queue, BackupQueueEntry.encodeList(queue));
        }
        await prefs.setString(BackupPrefsKeys.lastError, 'Google sign-in expired. Please sign in again.');
        final ds = BackupLocalDatasource(prefs: prefs);
        await ds.appendAuditLog(AuditLogEntry(
          timestamp: DateTime.now(),
          action: AuditAction.failure,
          backupName: 'auto',
          status: BackupStatus.failed,
          error: 'Auth expired',
        ));
        return false;
      }

      final drive = GoogleDriveService(auth: auth, prefs: prefs);
      await auth.getAuthHeaders();
      final folderId = await drive.ensureFolderId();

      final live = await DatabaseLocation.liveFile();
      if (!await live.exists()) return false;

      final dir = await getTemporaryDirectory();
      final tempDb = File(p.join(dir.path, 'utang_backup_temp.sqlite'));
      if (await tempDb.exists()) await tempDb.delete();
      await live.copy(tempDb.path);

      final now = DateTime.now().toUtc();
      final localNow = now.toLocal();
      final name = DateFormatters.backupFileName(localNow);
      final zipFile = File(p.join(dir.path, name));
      if (await zipFile.exists()) await zipFile.delete();

      final dbBytes = await tempDb.readAsBytes();
      final archive = Archive();
      archive.addFile(ArchiveFile('utang_tracker.sqlite', dbBytes.length, dbBytes));
      final zipBytes = ZipEncoder().encode(archive);
      if (zipBytes.isEmpty) return false;
      await zipFile.writeAsBytes(zipBytes);
      final hash = sha256.convert(zipBytes).toString();

      final storedHash = prefs.getString(BackupPrefsKeys.lastBackupHash);
      if (storedHash != null && storedHash == hash) {
        await prefs.setString(BackupPrefsKeys.lastError, 'Duplicate backup found. Upload skipped.');
        try { await tempDb.delete(); } catch (_) {}
        try { await zipFile.delete(); } catch (_) {}
        return true;
      }

      final existing = await drive.listBackupsInFolder();
      final duplicate = existing.any((m) => m.hash.isNotEmpty && m.hash == hash);
      if (duplicate) {
        await prefs.setString(BackupPrefsKeys.lastError, 'Duplicate backup found. Upload skipped.');
        try { await tempDb.delete(); } catch (_) {}
        try { await zipFile.delete(); } catch (_) {}
        return true;
      }

      final uploaded = await drive.uploadFile(zipFile, name, folderId, hash);

      await prefs.setInt(BackupPrefsKeys.lastBackupTime, now.millisecondsSinceEpoch);
      await prefs.setString(BackupPrefsKeys.lastBackupHash, hash);
      await prefs.setInt(BackupPrefsKeys.lastBackupSize, zipBytes.length);
      final next = interval.duration == null ? null : now.add(interval.duration!);
      if (next != null) {
        await prefs.setInt(BackupPrefsKeys.nextScheduledTime, next.millisecondsSinceEpoch);
      }
      await prefs.remove(BackupPrefsKeys.lastError);
      await prefs.remove(BackupPrefsKeys.queuedBackup);

      final ds = BackupLocalDatasource(prefs: prefs);
      await ds.appendHistory(BackupHistoryEntry(
        id: uploaded.id ?? name,
        backupName: name,
        createdTime: now,
        sizeBytes: zipBytes.length,
        status: BackupStatus.success,
        source: BackupSource.auto,
        hash: hash,
      ));
      await ds.appendAuditLog(AuditLogEntry(
        timestamp: now,
        action: AuditAction.backup,
        backupName: name,
        status: BackupStatus.success,
      ));

      try { await tempDb.delete(); } catch (_) {}
      try { await zipFile.delete(); } catch (_) {}
      return true;
    } catch (e) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final msg = e.toString();
        await prefs.setString(BackupPrefsKeys.lastError, msg);
        final ds = BackupLocalDatasource(prefs: prefs);
        await ds.appendAuditLog(AuditLogEntry(
          timestamp: DateTime.now(),
          action: AuditAction.failure,
          backupName: 'auto',
          status: BackupStatus.failed,
          error: msg,
        ));
        if (msg.toLowerCase().contains('401') || msg.toLowerCase().contains('auth')) {
          final queueRaw = prefs.getString(BackupPrefsKeys.queue);
          final queue = queueRaw == null || queueRaw.isEmpty
              ? <BackupQueueEntry>[]
              : BackupQueueEntry.decodeList(queueRaw);
          if (queue.length < 20) {
            queue.add(BackupQueueEntry(type: 'auto', timestamp: DateTime.now().toUtc(), retryCount: 0));
            await prefs.setString(BackupPrefsKeys.queue, BackupQueueEntry.encodeList(queue));
          }
        }
      } catch (_) {}
      return false;
    }
  });
}

class BackupScheduler {
  BackupScheduler();

  static const String taskName = 'utang_auto_backup';
  static const String uniqueName = 'utang_auto_backup_periodic';

  Future<void> initialize() async {
    // ignore: deprecated_member_use
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  Future<void> register(BackupInterval interval) async {
    if (interval == BackupInterval.off) {
      await Workmanager().cancelByUniqueName(uniqueName);
      return;
    }
    final freq = _frequency(interval);
    await Workmanager().registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: freq,
      initialDelay: freq,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
    );
  }

  Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(uniqueName);
  }

  Duration _frequency(BackupInterval interval) {
    final dur = interval.duration;
    if (dur == null) return const Duration(days: 1);
    if (dur.inMinutes < 15) return const Duration(minutes: 15);
    return dur;
  }
}
