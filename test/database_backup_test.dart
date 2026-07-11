import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:utang_tracker/core/database/database_backup.dart';
import 'package:utang_tracker/core/error/app_exception.dart';

void _createMinimalBackup(String path, {String customerName = 'Alice'}) {
  final db = sqlite3.sqlite3.open(path);
  db.execute('''
    CREATE TABLE customers (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      phone TEXT NULL,
      notes TEXT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER NULL
    );
    CREATE TABLE debts (
      id TEXT NOT NULL PRIMARY KEY,
      customer_id TEXT NOT NULL,
      total_amount INTEGER NOT NULL,
      paid_amount INTEGER NOT NULL,
      balance INTEGER NOT NULL,
      status TEXT NOT NULL,
      transaction_date INTEGER NOT NULL,
      due_date INTEGER NULL,
      notes TEXT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      deleted_at INTEGER NULL
    );
    CREATE TABLE debt_items (
      id TEXT NOT NULL PRIMARY KEY,
      debt_id TEXT NOT NULL,
      product_name TEXT NOT NULL,
      quantity REAL NOT NULL,
      unit_price INTEGER NOT NULL,
      subtotal INTEGER NOT NULL,
      deleted_at INTEGER NULL
    );
    CREATE TABLE payments (
      id TEXT NOT NULL PRIMARY KEY,
      debt_id TEXT NOT NULL,
      amount INTEGER NOT NULL,
      payment_date INTEGER NOT NULL,
      payment_method TEXT NOT NULL,
      notes TEXT NULL,
      created_at INTEGER NOT NULL,
      deleted_at INTEGER NULL
    );
  ''');
  db.execute("INSERT INTO customers VALUES ('c1', ?, NULL, NULL, 1, 1, NULL)", [
    customerName,
  ]);
  db.execute('PRAGMA user_version = 3');
  db.close();
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('utang_backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('hasAllowedExtension only allows sqlite and db', () {
    expect(DatabaseBackup.hasAllowedExtension('backup.sqlite'), isTrue);
    expect(DatabaseBackup.hasAllowedExtension('backup.db'), isTrue);
    expect(DatabaseBackup.hasAllowedExtension('BACKUP.SQLITE'), isTrue);
    expect(DatabaseBackup.hasAllowedExtension('backup.txt'), isFalse);
    expect(DatabaseBackup.hasAllowedExtension('backup'), isFalse);
  });

  test('validateBackupFile accepts valid backup', () {
    final path = p.join(tempDir.path, 'good.sqlite');
    _createMinimalBackup(path);
    expect(() => DatabaseBackup.validateBackupFile(path), returnsNormally);
  });

  test('validateBackupFile accepts .db extension', () {
    final path = p.join(tempDir.path, 'good.db');
    _createMinimalBackup(path);
    expect(() => DatabaseBackup.validateBackupFile(path), returnsNormally);
  });

  test('validateBackupFile rejects wrong extension', () {
    final path = p.join(tempDir.path, 'good.txt');
    _createMinimalBackup(path);
    expect(
      () => DatabaseBackup.validateBackupFile(path),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('.sqlite or .db'),
        ),
      ),
    );
  });

  test('validateBackupFile rejects missing tables', () {
    final path = p.join(tempDir.path, 'partial.sqlite');
    final db = sqlite3.sqlite3.open(path);
    db.execute('CREATE TABLE customers (id TEXT PRIMARY KEY, name TEXT)');
    db.close();

    expect(
      () => DatabaseBackup.validateBackupFile(path),
      throwsA(isA<AppException>()),
    );
  });

  test('validateBackupFile rejects empty file', () {
    final path = p.join(tempDir.path, 'empty.sqlite');
    File(path).writeAsBytesSync([]);
    expect(
      () => DatabaseBackup.validateBackupFile(path),
      throwsA(isA<AppException>()),
    );
  });

  test('replaceDatabaseFile overwrites live db', () async {
    final livePath = p.join(tempDir.path, 'live.sqlite');
    final importPath = p.join(tempDir.path, 'import.sqlite');
    _createMinimalBackup(livePath, customerName: 'Alice');
    _createMinimalBackup(importPath, customerName: 'Bob');

    await DatabaseBackup.replaceDatabaseFile(
      livePath: livePath,
      importPath: importPath,
    );

    final check = sqlite3.sqlite3.open(
      livePath,
      mode: sqlite3.OpenMode.readOnly,
    );
    final rows = check.select('SELECT name FROM customers');
    check.close();
    expect(rows.single['name'], 'Bob');
  });

  test('replaceDatabaseFile removes WAL and SHM sidecars', () async {
    final livePath = p.join(tempDir.path, 'live.sqlite');
    final importPath = p.join(tempDir.path, 'import.sqlite');
    _createMinimalBackup(livePath, customerName: 'Alice');
    _createMinimalBackup(importPath, customerName: 'Bob');

    final wal = File('$livePath-wal');
    final shm = File('$livePath-shm');
    await wal.writeAsString('stale-wal');
    await shm.writeAsString('stale-shm');

    await DatabaseBackup.replaceDatabaseFile(
      livePath: livePath,
      importPath: importPath,
    );

    expect(await wal.exists(), isFalse);
    expect(await shm.exists(), isFalse);
  });
}
