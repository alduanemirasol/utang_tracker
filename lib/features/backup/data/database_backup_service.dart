import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/database/database_location.dart';
import 'package:utang_tracker/features/backup/domain/backup_exception.dart';
import 'package:utang_tracker/features/backup/domain/backup_models.dart';

class DatabaseBackupService {
  DatabaseBackupService(
    this._database, {
    Future<Directory> Function()? temporaryDirectory,
    Future<Directory> Function()? documentsDirectory,
    Future<File> Function()? liveDatabaseFile,
    DateTime Function()? now,
    Future<void> Function()? afterReplacement,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _liveDatabaseFile = liveDatabaseFile ?? DatabaseLocation.liveFile,
       _now = now ?? DateTime.now,
       // Public test seam maps to a private implementation detail.
       // ignore: prefer_initializing_formals
       _afterReplacement = afterReplacement;

  final AppDatabase _database;
  final Future<Directory> Function() _temporaryDirectory;
  final Future<Directory> Function() _documentsDirectory;
  final Future<File> Function() _liveDatabaseFile;
  final DateTime Function() _now;
  final Future<void> Function()? _afterReplacement;

  Future<File> createExportSnapshot() async {
    final directory = await _temporaryDirectory();
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, _backupFileName('backup')));
    if (await file.exists()) await file.delete();

    await _database.customStatement(
      "VACUUM INTO '${_escapeSqlString(file.path)}'",
    );
    _validateOffline(file, requireCurrentSchema: true);
    return file;
  }

  Future<PreparedRestore> prepareRestore(File source) async {
    if (!await source.exists() || await source.length() == 0) {
      throw const BackupException(
        'The selected backup is empty or cannot be read.',
      );
    }

    final directory = await _temporaryDirectory();
    await directory.create(recursive: true);
    final staged = File(p.join(directory.path, _backupFileName('restore')));
    if (await staged.exists()) await staged.delete();
    await source.copy(staged.path);

    try {
      final originalVersion = _validateOffline(staged);
      if (originalVersion < AppDatabase.currentSchemaVersion) {
        final migrating = AppDatabase(NativeDatabase(staged));
        try {
          await migrating.customSelect('SELECT 1').get();
        } finally {
          await migrating.close();
        }
      }
      final currentVersion = _validateOffline(
        staged,
        requireCurrentSchema: true,
      );
      return PreparedRestore(
        file: staged,
        originalSchemaVersion: originalVersion,
        schemaVersion: currentVersion,
      );
    } on BackupException {
      await _deleteIfExists(staged);
      rethrow;
    } catch (error) {
      await _deleteIfExists(staged);
      throw BackupException(
        'This backup does not match a supported Utang Tracker database.',
        error,
      );
    }
  }

  Future<RestoreResult> restore(PreparedRestore prepared) async {
    _validateOffline(prepared.file, requireCurrentSchema: true);
    final rollback = await _createRollbackSnapshot();
    final live = await _liveDatabaseFile();
    final incoming = File('${live.path}.incoming');
    final displaced = File('${live.path}.pre_restore');

    await _deleteIfExists(incoming);
    await _deleteIfExists(displaced);
    await prepared.file.copy(incoming.path);

    await _database.close();
    try {
      if (await live.exists()) await live.rename(displaced.path);
      await incoming.rename(live.path);
      await _deleteSidecars(live);
      await _afterReplacement?.call();
      _validateOffline(live, requireCurrentSchema: true);
      await _verifyDriftCanOpen(live);
      await _deleteIfExists(displaced);
      return RestoreResult(
        rollbackBackup: rollback,
        wasMigrated: prepared.wasMigrated,
      );
    } catch (error) {
      var rollbackSucceeded = false;
      try {
        await _deleteIfExists(live);
        await rollback.copy(live.path);
        await _deleteSidecars(live);
        _validateOffline(live, requireCurrentSchema: true);
        await _verifyDriftCanOpen(live);
        rollbackSucceeded = true;
      } catch (rollbackError) {
        throw BackupException(
          'Restore and automatic rollback both failed. Your previous database is preserved at ${displaced.path}. The rollback file is at ${rollback.path}.',
          rollbackError,
        );
      } finally {
        await _deleteIfExists(incoming);
        if (rollbackSucceeded) await _deleteIfExists(displaced);
      }
      throw BackupException(
        'The restore failed. Your previous database was restored automatically.',
        error,
      );
    } finally {
      await _deleteIfExists(prepared.file);
    }
  }

  Future<File> _createRollbackSnapshot() async {
    final documents = await _documentsDirectory();
    final directory = Directory(p.join(documents.path, 'backups'));
    await directory.create(recursive: true);
    final rollback = File(
      p.join(directory.path, _backupFileName('before-restore')),
    );
    await _database.customStatement(
      "VACUUM INTO '${_escapeSqlString(rollback.path)}'",
    );
    _validateOffline(rollback, requireCurrentSchema: true);
    return rollback;
  }

  int _validateOffline(File file, {bool requireCurrentSchema = false}) {
    Database? raw;
    try {
      raw = sqlite3.open(file.path);
      final integrity = raw
          .select('PRAGMA integrity_check')
          .map((row) => row.values.first.toString());
      if (integrity.length != 1 || integrity.first.toLowerCase() != 'ok') {
        throw const BackupException(
          'The backup failed SQLite integrity validation.',
        );
      }
      if (raw.select('PRAGMA foreign_key_check').isNotEmpty) {
        throw const BackupException(
          'The backup contains broken data relationships.',
        );
      }

      final applicationId = _pragmaInt(raw, 'application_id');
      if (applicationId != AppDatabase.applicationId) {
        throw const BackupException(
          'This file was not created by Utang Tracker.',
        );
      }
      final version = _pragmaInt(raw, 'user_version');
      if (version < 1) {
        throw const BackupException(
          'The backup has no supported database schema version.',
        );
      }
      if (version > AppDatabase.currentSchemaVersion) {
        throw BackupException(
          'This backup uses schema $version, but this app supports up to schema ${AppDatabase.currentSchemaVersion}. Update the app before restoring it.',
        );
      }
      if (requireCurrentSchema) {
        if (version != AppDatabase.currentSchemaVersion) {
          throw const BackupException(
            'The backup could not be migrated to the current schema.',
          );
        }
        _validateCurrentStructure(raw);
      }
      return version;
    } on BackupException {
      rethrow;
    } catch (error) {
      throw BackupException(
        'The selected file is not a valid SQLite backup.',
        error,
      );
    } finally {
      raw?.close();
    }
  }

  void _validateCurrentStructure(Database database) {
    const expected = <String, Set<String>>{
      'customers': {
        'id',
        'name',
        'phone',
        'notes',
        'created_at',
        'updated_at',
        'deleted_at',
      },
      'debts': {
        'id',
        'customer_id',
        'total_amount',
        'paid_amount',
        'balance',
        'status',
        'transaction_date',
        'due_date',
        'notes',
        'created_at',
        'updated_at',
        'deleted_at',
      },
      'debt_items': {
        'id',
        'debt_id',
        'product_name',
        'quantity',
        'unit',
        'price',
        'deleted_at',
      },
      'payments': {
        'id',
        'debt_id',
        'amount',
        'payment_date',
        'payment_method',
        'notes',
        'created_at',
        'deleted_at',
      },
    };
    for (final entry in expected.entries) {
      final columns = database
          .select('PRAGMA table_info(${entry.key})')
          .map((row) => row['name'] as String)
          .toSet();
      if (!columns.containsAll(entry.value)) {
        throw const BackupException(
          'The backup schema does not match Utang Tracker.',
        );
      }
    }
  }

  Future<void> _verifyDriftCanOpen(File file) async {
    final database = AppDatabase(NativeDatabase(file));
    try {
      await database.customSelect('SELECT 1').get();
    } finally {
      await database.close();
    }
  }

  static int _pragmaInt(Database database, String pragma) {
    return database.select('PRAGMA $pragma').single.values.first as int;
  }

  String _backupFileName(String suffix) {
    final value = _now().toUtc().toIso8601String().replaceAll(':', '-');
    return 'utang-tracker-$suffix-$value.sqlite';
  }

  static String _escapeSqlString(String value) => value.replaceAll("'", "''");

  static Future<void> _deleteSidecars(File database) async {
    await _deleteIfExists(File('${database.path}-wal'));
    await _deleteIfExists(File('${database.path}-shm'));
  }

  static Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }
}
