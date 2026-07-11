import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/error/app_exception.dart';

/// Export and import the app's SQLite database file.
class DatabaseBackup {
  DatabaseBackup._();

  static final _stamp = DateFormat('yyyyMMdd_HHmmss');

  /// Flush WAL so the main DB file is consistent, then return its path.
  static Future<String> resolveDatabasePath(AppDatabase db) async {
    await db.customStatement('PRAGMA wal_checkpoint(FULL)');

    final rows = await db.customSelect('PRAGMA database_list').get();
    for (final row in rows) {
      final name = row.read<String>('name');
      if (name == 'main') {
        final file = row.readNullable<String>('file');
        if (file != null && file.isNotEmpty) {
          return file;
        }
      }
    }

    // Fallback for drift_flutter default layout.
    final dir = await getApplicationDocumentsDirectory();
    final fallback = p.join(dir.path, 'utang_tracker.sqlite');
    if (await File(fallback).exists()) return fallback;

    throw const AppException('Could not locate the database file.');
  }

  /// Copy the live database to a timestamped temp file and open the share sheet.
  static Future<void> exportAndShare(AppDatabase db) async {
    final sourcePath = await resolveDatabasePath(db);
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const AppException('Database file not found.');
    }

    final tempDir = await getTemporaryDirectory();
    final fileName =
        'utang_tracker_backup_${_stamp.format(DateTime.now())}.sqlite';
    final dest = File(p.join(tempDir.path, fileName));
    await source.copy(dest.path);

    await Share.shareXFiles(
      [XFile(dest.path, mimeType: 'application/x-sqlite3', name: fileName)],
      subject: 'Utang Tracker backup',
      text: 'Database backup for Utang Tracker.',
    );
  }

  /// Allowed backup file extensions (no leading dot).
  static const allowedExtensions = {'sqlite', 'db'};

  /// True when [fileNameOrPath] ends with `.sqlite` or `.db` (case-insensitive).
  static bool hasAllowedExtension(String fileNameOrPath) {
    final ext = p.extension(fileNameOrPath).toLowerCase();
    if (ext.isEmpty) return false;
    // p.extension includes the leading dot, e.g. ".sqlite"
    return allowedExtensions.contains(ext.substring(1));
  }

  /// Validate that [filePath] looks like an Utang Tracker SQLite database.
  static void validateBackupFile(String filePath) {
    if (!hasAllowedExtension(filePath)) {
      throw const AppException(
        'Only .sqlite or .db backup files can be imported.',
      );
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      throw const AppException('Selected file does not exist.');
    }
    if (file.lengthSync() == 0) {
      throw const AppException('Selected file is empty.');
    }

    sqlite3.Database? probe;
    try {
      probe = sqlite3.sqlite3.open(filePath, mode: sqlite3.OpenMode.readOnly);
      final tables = probe
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
          )
          .map((row) => row['name'] as String)
          .toSet();

      const required = {'customers', 'debts', 'debt_items', 'payments'};
      final missing = required.difference(tables);
      if (missing.isNotEmpty) {
        throw AppException(
          'This file is not a valid Utang Tracker backup '
          '(missing: ${missing.join(', ')}).',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Could not read backup file: $e');
    } finally {
      probe?.close();
    }
  }

  /// Replace the live database file with [importPath].
  ///
  /// [db] must already be closed before calling this.
  static Future<void> replaceDatabaseFile({
    required String livePath,
    required String importPath,
  }) async {
    validateBackupFile(importPath);

    final live = File(livePath);
    final parent = live.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    // Remove WAL/SHM so the imported file is not mixed with old journals.
    for (final suffix in ['-wal', '-shm']) {
      final side = File('$livePath$suffix');
      if (await side.exists()) {
        await side.delete();
      }
    }

    await File(importPath).copy(livePath);
  }
}
