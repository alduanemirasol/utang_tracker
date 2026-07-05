import 'package:riverpod/riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final databaseProvider = Provider<Database>((ref) => ref.read(appDatabaseProvider).db);
