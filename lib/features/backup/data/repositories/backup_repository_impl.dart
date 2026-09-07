import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:utang_tracker/features/backup/data/datasources/backup_queue_entry.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/database/database_location.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_local_datasource.dart';
import 'package:utang_tracker/features/backup/data/datasources/backup_prefs_keys.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_auth_datasource.dart';
import 'package:utang_tracker/features/backup/data/datasources/google_drive_service.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_action.dart';
import 'package:utang_tracker/features/backup/domain/entities/audit_log_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_history_entry.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_interval.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_meta.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_source.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_status.dart';
import 'package:utang_tracker/features/backup/domain/entities/storage_quota.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl({
    AppDatabase? database,
    GoogleAuthDatasource? auth,
    GoogleDriveService? driveService,
    BackupLocalDatasource? localDatasource,
    SharedPreferences? prefs,
    Future<Directory> Function()? tempDir,
    Future<File> Function()? liveFile,
    Connectivity? connectivity,
  })  : _database = database,
        _auth = auth,
        _driveService = driveService,
        _localDatasource = localDatasource ?? BackupLocalDatasource(),
        _prefsOverride = prefs,
        _tempDir = tempDir ?? getTemporaryDirectory,
        _liveFile = liveFile ?? DatabaseLocation.liveFile,
        _connectivity = connectivity ?? Connectivity();

  final AppDatabase? _database;
  final GoogleAuthDatasource? _auth;
  final GoogleDriveService? _driveService;
  final BackupLocalDatasource _localDatasource;
  final SharedPreferences? _prefsOverride;
  final Future<Directory> Function() _tempDir;
  final Future<File> Function() _liveFile;
  final Connectivity _connectivity;

  GoogleAuthDatasource get _authOrCreate =>
      _auth ?? GoogleAuthDatasource();
  GoogleDriveService get _driveOrCreate => _driveService ??
      GoogleDriveService(auth: _authOrCreate, prefs: _prefsOverride);

  Future<SharedPreferences> _getPrefs() async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  @override
  Future<List<BackupMeta>> listBackups() => browseBackups();

  @override
  Future<List<BackupMeta>> browseBackups() async {
    try {
      return await _driveOrCreate.listBackupsInFolder();
    } catch (e) {
      if (e is AppException) rethrow;
      throw BackupException('Failed to list backups: $e');
    }
  }

  @override
  Future<BackupMeta> createBackup() async {
    final connectivity = await _connectivity.checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none) ||
        connectivity.isEmpty;
    if (isOffline) {
      await _enqueuePending();
      throw const NetworkException('No internet connection. Backup queued.');
    }

    await _authOrCreate.getAuthHeaders();
    final folderId = await _driveOrCreate.ensureFolderId();

    if (_database != null) {
      try {
        await _database.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (_) {}
    }

    final live = await _liveFile();
    if (!await live.exists()) {
      throw const BackupException('Database file not found.');
    }

    final dir = await _tempDir();
    await dir.create(recursive: true);
    final tempDb = File(p.join(dir.path, 'utang_backup_temp.sqlite'));
    await _copyWithRetry(live, tempDb);

    final now = DateTime.now();
    final name = DateFormatters.backupFileName(now);
    final zipFile = File(p.join(dir.path, name));
    if (await zipFile.exists()) await zipFile.delete();

    final dbBytes = await tempDb.readAsBytes();
    final archive = Archive();
    archive.addFile(ArchiveFile('utang_tracker.sqlite', dbBytes.length, dbBytes));
    final zipBytes = ZipEncoder().encode(archive);
    await zipFile.writeAsBytes(zipBytes);

    final size = zipBytes.length;
    if (size == 0) {
      throw const IntegrityException('Backup zip is empty.');
    }
    final hash = sha256.convert(zipBytes).toString();

    final existing = await _driveOrCreate.listBackupsInFolder();
    for (final m in existing) {
      if (m.name == name) {
        throw DuplicateBackupException('Backup with same name already exists: $name');
      }
      if (m.hash.isNotEmpty && m.hash == hash) {
        throw DuplicateBackupException('Backup with same content already exists.');
      }
    }

    final prefs = await _getPrefs();
    final lastHash = prefs.getString(BackupPrefsKeys.lastBackupHash);
    if (lastHash != null && lastHash == hash) {
      final existingHashMatch = existing.any((e) => e.hash == hash);
      if (existingHashMatch) {
        throw DuplicateBackupException('Duplicate backup detected by hash.');
      }
    }

    dynamic uploaded;
    int attempts = 0;
    while (attempts < 3) {
      try {
        uploaded = await _driveOrCreate.uploadFile(zipFile, name, folderId, hash);
        break;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('401') || msg.contains('invalid_grant')) {
          throw AuthExpiredException('Authentication expired, please sign in again. $e');
        }
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempts)));
      }
    }

    await _verifyIntegrity(uploaded, hash, size);

    await prefs.setInt(BackupPrefsKeys.lastBackupTime, now.millisecondsSinceEpoch);
    await prefs.setString(BackupPrefsKeys.lastBackupHash, hash);
    await prefs.setInt(BackupPrefsKeys.lastBackupSize, size);
    final intervalStr = prefs.getString(BackupPrefsKeys.interval) ?? BackupInterval.off.name;
    final interval = BackupIntervalX.fromName(intervalStr);
    final next = _nextScheduled(now, interval);
    if (next != null) {
      await prefs.setInt(BackupPrefsKeys.nextScheduledTime, next.millisecondsSinceEpoch);
    } else {
      await prefs.remove(BackupPrefsKeys.nextScheduledTime);
    }
    await prefs.remove(BackupPrefsKeys.queuedBackup);
    await prefs.setString(BackupPrefsKeys.queue, '[]');
    await prefs.remove(BackupPrefsKeys.lastError);

    final meta = BackupMeta(
      id: uploaded.id as String,
      name: name,
      createdTime: now,
      sizeBytes: size,
      status: BackupStatus.success,
      source: BackupSource.manual,
      hash: hash,
    );

    await _localDatasource.appendHistory(
      BackupHistoryEntry(
        id: meta.id,
        backupName: meta.name,
        createdTime: meta.createdTime,
        sizeBytes: meta.sizeBytes,
        status: BackupStatus.success,
        source: BackupSource.manual,
        hash: hash,
      ),
    );
    await _localDatasource.appendAuditLog(
      AuditLogEntry(
        timestamp: now,
        action: AuditAction.backup,
        backupName: name,
        status: BackupStatus.success,
      ),
    );

    try {
      await tempDb.delete();
    } catch (_) {}
    try {
      await zipFile.delete();
    } catch (_) {}

    return meta;
  }

  @override
  Future<void> restoreBackup(String id,
      {bool confirmed = false, void Function(double)? onProgress}) async {
    if (!confirmed) {
      throw const ValidationException('Restore requires confirmation.');
    }
    final connectivity = await _connectivity.checkConnectivity();
    final isOffline = connectivity.contains(ConnectivityResult.none) ||
        connectivity.isEmpty;
    if (isOffline) {
      throw const NetworkException('No internet connection.');
    }
    await _authOrCreate.getAuthHeaders();
    await _driveOrCreate.ensureFolderId();

    final tmpDir = await _tempDir();
    await tmpDir.create(recursive: true);
    final zipDest = File(p.join(tmpDir.path, 'restore_$id.zip'));
    if (await zipDest.exists()) await zipDest.delete();

    await _driveOrCreate.downloadFile(id, zipDest, onProgress: onProgress);

    final zipBytes = await zipDest.readAsBytes();
    if (zipBytes.isEmpty) {
      throw const IntegrityException('Downloaded backup is empty.');
    }
    final downloadedHash = sha256.convert(zipBytes).toString();

    final metas = await _driveOrCreate.listBackupsInFolder();
    final meta = metas.where((m) => m.id == id).firstOrNull;
    if (meta != null && meta.hash.isNotEmpty && meta.hash != downloadedHash) {
      throw IntegrityException('Hash mismatch: expected ${meta.hash} got $downloadedHash');
    }

    final archive = ZipDecoder().decodeBytes(zipBytes);
    if (archive.isEmpty) {
      throw const IntegrityException('Backup zip is empty.');
    }
    final entry = archive.files.firstWhere(
      (f) => f.name.endsWith('.sqlite') || f.name.contains('utang'),
      orElse: () => archive.files.first,
    );
    final sqliteBytes = entry.content as List<int>;
    if (sqliteBytes.isEmpty) {
      throw const IntegrityException('Unzipped database is empty.');
    }
    if (!_hasSqliteHeader(Uint8List.fromList(sqliteBytes))) {
      throw const IntegrityException('Invalid SQLite header.');
    }

    final extracted = File(p.join(tmpDir.path, 'restored_$id.sqlite'));
    await extracted.writeAsBytes(sqliteBytes);
    if (await extracted.length() == 0) {
      throw const IntegrityException('Extracted file size is 0.');
    }
    await _pragmaIntegrityCheck(extracted);

    final live = await _liveFile();
    final preRestoreName = DateFormatters.preRestoreFileName(DateTime.now());
    final preRestore = File(p.join(live.parent.path, preRestoreName));
    if (await live.exists()) {
      await _copyWithRetry(live, preRestore);
    }

    final incoming = File('${live.path}.incoming');
    await extracted.copy(incoming.path);

    if (_database != null) {
      try {
        await _database.close();
      } catch (_) {}
    }

    try {
      if (await live.exists()) await live.delete();
      await incoming.rename(live.path);
      await _deleteSidecars(live);
      await _pragmaIntegrityCheck(live);
      await _verifyDriftCanOpen(live);
    } catch (e) {
      try {
        if (await live.exists()) await live.delete();
        await preRestore.copy(live.path);
        await _deleteSidecars(live);
      } catch (_) {}
      throw BackupException('Restore failed and rolled back: $e');
    } finally {
      try {
        await zipDest.delete();
      } catch (_) {}
      try {
        await extracted.delete();
      } catch (_) {}
      try {
        if (await incoming.exists()) await incoming.delete();
      } catch (_) {}
    }

    final now = DateTime.now();
    await _localDatasource.appendAuditLog(
      AuditLogEntry(
        timestamp: now,
        action: AuditAction.restore,
        backupName: meta?.name ?? id,
        status: BackupStatus.success,
      ),
    );
    await _localDatasource.appendHistory(
      BackupHistoryEntry(
        id: id,
        backupName: meta?.name ?? id,
        createdTime: now,
        sizeBytes: sqliteBytes.length,
        status: BackupStatus.success,
        source: BackupSource.manual,
        hash: downloadedHash,
      ),
    );
  }

  @override
  Future<void> deleteBackup(String id) async {
    await _authOrCreate.getAuthHeaders();
    await _driveOrCreate.ensureFolderId();
    try {
      await _driveOrCreate.deleteFile(id);
      await _localDatasource.appendAuditLog(
        AuditLogEntry(
          timestamp: DateTime.now(),
          action: AuditAction.deletion,
          backupName: id,
          status: BackupStatus.success,
        ),
      );
    } catch (e) {
      await _localDatasource.appendAuditLog(
        AuditLogEntry(
          timestamp: DateTime.now(),
          action: AuditAction.failure,
          backupName: id,
          status: BackupStatus.failed,
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }

  @override
  Future<StorageQuota> getQuota() async {
    await _authOrCreate.getAuthHeaders();
    await _driveOrCreate.ensureFolderId();
    final quota = await _driveOrCreate.getStorageQuota();
    return quota;
  }

  @override
  Future<bool> isLowStorage() async {
    try {
      final quota = await getQuota();
      if (quota.totalBytes != null && quota.availableBytes != null) {
        final free = quota.availableBytes!;
        if (free < 500 * 1024 * 1024) return true;
        if (quota.totalBytes! > 0) {
          final usedPct = quota.usedBytes / quota.totalBytes!;
          if (usedPct > 0.8) return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _verifyIntegrity(
      dynamic uploaded, String hash, int size) async {
    final uploadedSize = uploaded.size == null ? null : int.tryParse(uploaded.size as String);
    if (uploadedSize != null && uploadedSize != size) {
      throw IntegrityException('Upload size mismatch: expected $size got $uploadedSize');
    }
    final fileId = uploaded.id as String;
    final bytes = await _driveOrCreate.downloadBytes(fileId);
    final downloadedHash = sha256.convert(bytes).toString();
    if (downloadedHash != hash) {
      throw IntegrityException('SHA256 mismatch after upload.');
    }
    final archive = ZipDecoder().decodeBytes(bytes);
    if (archive.isEmpty) {
      throw const IntegrityException('Downloaded zip empty.');
    }
    final entry = archive.files.first;
    final content = entry.content as List<int>;
    if (content.isEmpty) {
      throw const IntegrityException('Unzipped content empty.');
    }
    if (!_hasSqliteHeader(Uint8List.fromList(content))) {
      throw const IntegrityException('Invalid SQLite header in downloaded file.');
    }
    final tmp = File(p.join((await _tempDir()).path, 'integrity_${DateTime.now().millisecondsSinceEpoch}.sqlite'));
    await tmp.writeAsBytes(content);
    try {
      await _pragmaIntegrityCheck(tmp);
    } finally {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  bool _hasSqliteHeader(Uint8List bytes) {
    if (bytes.length < 16) return false;
    const header = 'SQLite format 3\x00';
    final headerBytes = utf8.encode(header);
    for (int i = 0; i < headerBytes.length; i++) {
      if (bytes[i] != headerBytes[i]) return false;
    }
    return true;
  }

  Future<void> _pragmaIntegrityCheck(File file) async {
    sqlite3.Database? raw;
    try {
      raw = sqlite3.sqlite3.open(file.path);
      final result = raw.select('PRAGMA integrity_check');
      if (result.isEmpty || result.first.values.first.toString().toLowerCase() != 'ok') {
        throw const IntegrityException('PRAGMA integrity_check failed.');
      }
      if (raw.select('PRAGMA foreign_key_check').isNotEmpty) {
        throw const IntegrityException('Foreign key check failed.');
      }
    } catch (e) {
      if (e is IntegrityException) rethrow;
      throw IntegrityException('Integrity check failed: $e');
    } finally {
      // ignore: deprecated_member_use
      raw?.dispose();
    }
    final db = AppDatabase(NativeDatabase(file));
    try {
      await db.customSelect('SELECT 1').get();
    } finally {
      await db.close();
    }
  }

  Future<void> _verifyDriftCanOpen(File file) async {
    final db = AppDatabase(NativeDatabase(file));
    try {
      await db.customSelect('SELECT 1').get();
    } finally {
      await db.close();
    }
  }

  Future<void> _copyWithRetry(File src, File dst) async {
    int attempts = 0;
    while (true) {
      try {
        if (await dst.exists()) await dst.delete();
        await src.copy(dst.path);
        return;
      } catch (e) {
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: 200 * attempts));
      }
    }
  }

  Future<void> _deleteSidecars(File db) async {
    for (final suffix in ['-wal', '-shm']) {
      final f = File('${db.path}$suffix');
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }

  DateTime? _nextScheduled(DateTime from, BackupInterval interval) {
    switch (interval) {
      case BackupInterval.off:
        return null;
      case BackupInterval.daily:
        return from.add(const Duration(days: 1));
      case BackupInterval.threeDays:
        return from.add(const Duration(days: 3));
      case BackupInterval.weekly:
        return from.add(const Duration(days: 7));
    }
  }

  Future<void> _enqueuePending() async {
    final prefs = await _getPrefs();
    await prefs.setBool(BackupPrefsKeys.queuedBackup, true);
    final raw = prefs.getString(BackupPrefsKeys.queue);
    final queue = raw == null || raw.isEmpty ? <BackupQueueEntry>[] : BackupQueueEntry.decodeList(raw);
    if (queue.length < 20) {
      final exists = queue.any((e) => e.type == 'manual' && e.retryCount == 0);
      if (!exists) {
        queue.add(BackupQueueEntry(type: 'manual', timestamp: DateTime.now().toUtc(), retryCount: 0));
        await prefs.setString(BackupPrefsKeys.queue, BackupQueueEntry.encodeList(queue));
      }
    }
    await prefs.setString(BackupPrefsKeys.lastError, 'No internet connection. Backup queued and will be retried later.');
    await _localDatasource.appendAuditLog(
      AuditLogEntry(
        timestamp: DateTime.now(),
        action: AuditAction.failure,
        backupName: 'queued',
        status: BackupStatus.failed,
        error: 'No internet - queued',
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
