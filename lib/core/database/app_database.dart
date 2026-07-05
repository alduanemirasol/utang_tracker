import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'tables.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._();
  factory AppDatabase() => _instance;
  AppDatabase._();

  Database? _db;
  Database get db {
    if (_db == null) throw StateError('Database not initialized');
    return _db!;
  }

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'utang_tracker.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON');
        for (final stmt in allCreateStatements) {
          await db.execute(stmt);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          for (final stmt in migrationStatementsV2) {
            await db.execute(stmt);
          }
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
