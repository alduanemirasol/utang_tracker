import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/features/backup/data/database_backup_service.dart';
import 'package:utang_tracker/features/backup/domain/backup_exception.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('utang_backup_test_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('export snapshot preserves every stored value', () async {
    final sourceFile = File(p.join(root.path, 'source.sqlite'));
    final database = AppDatabase(NativeDatabase(sourceFile));
    await _seed(database, 'source');
    final service = _service(database, sourceFile, 'export');

    final snapshot = await service.createExportSnapshot();

    final sourceRows = _allBusinessRows(sourceFile);
    final snapshotRows = _allBusinessRows(snapshot);
    expect(snapshotRows, sourceRows);
    final raw = sqlite3.open(snapshot.path);
    expect(
      raw.select('PRAGMA application_id').single.values.first,
      AppDatabase.applicationId,
    );
    expect(
      raw.select('PRAGMA user_version').single.values.first,
      AppDatabase.currentSchemaVersion,
    );
    raw.close();
    await database.close();
  });

  test('prepare rejects backups from another application', () async {
    final fixture = await _currentBackup('foreign');
    final raw = sqlite3.open(fixture.path);
    raw.execute('PRAGMA application_id = 1234');
    raw.close();
    final liveFile = File(p.join(root.path, 'live.sqlite'));
    final live = AppDatabase(NativeDatabase(liveFile));
    await _seed(live, 'live');

    expect(
      () => _service(live, liveFile, 'foreign-stage').prepareRestore(fixture),
      throwsA(
        isA<BackupException>().having(
          (error) => error.kind,
          'kind',
          BackupFailureKind.wrongApplication,
        ),
      ),
    );
    await live.close();
  });

  test('prepare rejects a newer schema version', () async {
    final fixture = await _currentBackup('newer');
    final raw = sqlite3.open(fixture.path);
    raw.execute(
      'PRAGMA user_version = ${AppDatabase.currentSchemaVersion + 1}',
    );
    raw.close();
    final liveFile = File(p.join(root.path, 'live.sqlite'));
    final live = AppDatabase(NativeDatabase(liveFile));
    await _seed(live, 'live');

    expect(
      () => _service(live, liveFile, 'newer-stage').prepareRestore(fixture),
      throwsA(
        isA<BackupException>().having(
          (error) => error.kind,
          'kind',
          BackupFailureKind.unsupportedSchema,
        ),
      ),
    );
    await live.close();
  });

  test(
    'prepare migrates a valid schema 4 backup without changing data',
    () async {
      final oldFile = File(p.join(root.path, 'schema4.sqlite'));
      _createSchema4(oldFile);
      final liveFile = File(p.join(root.path, 'live.sqlite'));
      final live = AppDatabase(NativeDatabase(liveFile));
      await _seed(live, 'live');

      final prepared = await _service(
        live,
        liveFile,
        'migration-stage',
      ).prepareRestore(oldFile);

      expect(prepared.originalSchemaVersion, 4);
      expect(prepared.schemaVersion, AppDatabase.currentSchemaVersion);
      expect(prepared.wasMigrated, isTrue);
      final raw = sqlite3.open(prepared.file.path);
      final item = raw
          .select('SELECT quantity, unit, price FROM debt_items')
          .single;
      expect(item['quantity'], 2.5);
      expect(item['unit'], 'kg');
      expect(item['price'], 12500);
      raw.close();
      await live.close();
    },
  );

  test(
    'restore replaces rather than merges data and keeps rollback backup',
    () async {
      final source = await _currentBackup('incoming');
      final liveFile = File(p.join(root.path, 'live.sqlite'));
      final live = AppDatabase(NativeDatabase(liveFile));
      await _seed(live, 'old');
      final service = _service(live, liveFile, 'restore-stage');
      final prepared = await service.prepareRestore(source);

      final result = await service.restore(prepared);

      expect(await result.rollbackBackup.exists(), isTrue);
      expect(_allBusinessRows(liveFile), _allBusinessRows(source));
      expect(_allBusinessRows(liveFile).toString(), contains('incoming'));
      expect(_allBusinessRows(liveFile).toString(), isNot(contains('old')));
    },
  );

  test(
    'failed activation automatically restores the original database',
    () async {
      final source = await _currentBackup('incoming-failure');
      final liveFile = File(p.join(root.path, 'live.sqlite'));
      final live = AppDatabase(NativeDatabase(liveFile));
      await _seed(live, 'original');
      final before = _allBusinessRows(liveFile);
      final service = _service(
        live,
        liveFile,
        'rollback-stage',
        afterReplacement: () async => throw StateError('simulated failure'),
      );
      final prepared = await service.prepareRestore(source);

      await expectLater(
        () => service.restore(prepared),
        throwsA(
          isA<BackupException>().having(
            (error) => error.message,
            'message',
            contains('restored automatically'),
          ),
        ),
      );
      expect(_allBusinessRows(liveFile), before);
    },
  );

  test(
    'failed activation keeps displaced database when rollback also fails',
    () async {
      final source = await _currentBackup('incoming-double-failure');
      final liveFile = File(p.join(root.path, 'live.sqlite'));
      final live = AppDatabase(NativeDatabase(liveFile));
      await _seed(live, 'original-double-failure');
      final before = _allBusinessRows(liveFile);
      final rollback = File(
        p.join(
          root.path,
          'rollback-double-failure-stage-docs',
          'backups',
          'utang-tracker-before-restore-2026-07-28T13-00-00.000Z.sqlite',
        ),
      );
      final service = _service(
        live,
        liveFile,
        'rollback-double-failure-stage',
        afterReplacement: () async {
          await rollback.delete();
          throw StateError('simulated activation failure');
        },
      );
      final prepared = await service.prepareRestore(source);
      final displaced = File('${liveFile.path}.pre_restore');

      await expectLater(
        () => service.restore(prepared),
        throwsA(
          isA<BackupException>()
              .having((error) => error.kind, 'kind', BackupFailureKind.restore)
              .having(
                (error) => error.message,
                'message',
                allOf(contains('both failed'), contains(displaced.path)),
              ),
        ),
      );

      expect(await displaced.exists(), isTrue);
      expect(_allBusinessRows(displaced), before);
      expect(await File('${liveFile.path}.incoming').exists(), isFalse);
    },
  );
}

DatabaseBackupService _service(
  AppDatabase database,
  File liveFile,
  String tempName, {
  Future<void> Function()? afterReplacement,
}) {
  final temp = Directory(p.join(liveFile.parent.path, tempName));
  final documents = Directory(p.join(liveFile.parent.path, '$tempName-docs'));
  return DatabaseBackupService(
    database,
    temporaryDirectory: () async => temp,
    documentsDirectory: () async => documents,
    liveDatabaseFile: () async => liveFile,
    now: () => DateTime.utc(2026, 7, 28, 13, 0),
    afterReplacement: afterReplacement,
  );
}

Future<File> _currentBackup(String label) async {
  final directory = await Directory.systemTemp.createTemp('backup_fixture_');
  addTearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });
  final file = File(p.join(directory.path, '$label.sqlite'));
  final database = AppDatabase(NativeDatabase(file));
  await _seed(database, label);
  final snapshot = await DatabaseBackupService(
    database,
    temporaryDirectory: () async => directory,
    documentsDirectory: () async => directory,
    liveDatabaseFile: () async => file,
    now: () => DateTime.utc(2026, 7, 28, 14, label.length),
  ).createExportSnapshot();
  await database.close();
  return snapshot;
}

Future<void> _seed(AppDatabase database, String label) async {
  await database.customStatement(
    'INSERT INTO customers '
    '(id, name, phone, notes, created_at, updated_at, deleted_at) '
    "VALUES ('customer-$label', 'Name $label', NULL, 'note-$label', 100, 200, NULL)",
  );
  await database.customStatement(
    'INSERT INTO debts '
    '(id, customer_id, total_amount, paid_amount, balance, status, '
    'transaction_date, due_date, notes, created_at, updated_at, deleted_at) '
    "VALUES ('debt-$label', 'customer-$label', 15000, 5000, 10000, "
    "'partial', 300, NULL, NULL, 300, 400, NULL)",
  );
  await database.customStatement(
    'INSERT INTO debt_items '
    '(id, debt_id, product_name, quantity, unit, price, deleted_at) '
    "VALUES ('item-$label', 'debt-$label', 'Rice $label', 2.5, 'kg', 15000, 999)",
  );
  await database.customStatement(
    'INSERT INTO payments '
    '(id, debt_id, amount, payment_date, payment_method, notes, created_at, deleted_at) '
    "VALUES ('payment-$label', 'debt-$label', 5000, 500, 'Cash', NULL, 500, NULL)",
  );
}

Map<String, List<List<Object?>>> _allBusinessRows(File file) {
  final raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    return {
      for (final table in ['customers', 'debts', 'debt_items', 'payments'])
        table: raw
            .select('SELECT * FROM $table ORDER BY id')
            .map((row) => row.values.toList(growable: false))
            .toList(growable: false),
    };
  } finally {
    raw.close();
  }
}

void _createSchema4(File file) {
  final raw = sqlite3.open(file.path);
  raw.execute('PRAGMA foreign_keys = ON');
  raw.execute('''
CREATE TABLE customers (
  id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, phone TEXT NULL,
  notes TEXT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
  deleted_at INTEGER NULL
)''');
  raw.execute('''
CREATE TABLE debts (
  id TEXT NOT NULL PRIMARY KEY,
  customer_id TEXT NOT NULL REFERENCES customers(id),
  total_amount INTEGER NOT NULL, paid_amount INTEGER NOT NULL,
  balance INTEGER NOT NULL, status TEXT NOT NULL,
  transaction_date INTEGER NOT NULL, due_date INTEGER NULL, notes TEXT NULL,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
  deleted_at INTEGER NULL
)''');
  raw.execute('''
CREATE TABLE debt_items (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL REFERENCES debts(id), product_name TEXT NOT NULL,
  quantity REAL NOT NULL, unit TEXT NOT NULL DEFAULT 'piece',
  unit_price INTEGER NOT NULL, subtotal INTEGER NOT NULL,
  deleted_at INTEGER NULL
)''');
  raw.execute('''
CREATE TABLE payments (
  id TEXT NOT NULL PRIMARY KEY,
  debt_id TEXT NOT NULL REFERENCES debts(id), amount INTEGER NOT NULL,
  payment_date INTEGER NOT NULL, payment_method TEXT NOT NULL,
  notes TEXT NULL, created_at INTEGER NOT NULL, deleted_at INTEGER NULL
)''');
  raw.execute(
    "INSERT INTO customers VALUES ('customer-1', 'Customer', NULL, NULL, 1, 2, NULL)",
  );
  raw.execute(
    "INSERT INTO debts VALUES ('debt-1', 'customer-1', 12500, 0, 12500, 'unpaid', 3, NULL, NULL, 3, 3, NULL)",
  );
  raw.execute(
    "INSERT INTO debt_items VALUES ('item-1', 'debt-1', 'Rice', 2.5, 'kg', 5000, 12500, NULL)",
  );
  raw.execute('PRAGMA application_id = ${AppDatabase.applicationId}');
  raw.execute('PRAGMA user_version = 4');
  raw.close();
}
