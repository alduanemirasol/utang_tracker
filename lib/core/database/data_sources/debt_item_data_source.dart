import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';

class DebtItemDataSource {
  final Database db;

  DebtItemDataSource(this.db);

  Future<List<Map<String, dynamic>>> getByDebtId(String debtId) async {
    return db.query(
      tableDebtItems,
      where: '$columnDebtId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [debtId],
      orderBy: '$columnProductName ASC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final results = await db.query(
      tableDebtItems,
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> map, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.insert(tableDebtItems, map);
  }

  Future<void> update(Map<String, dynamic> map, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebtItems,
      map,
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [map[columnId]],
    );
  }

  Future<void> delete(String id, String deletedAt,
      [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebtItems,
      {columnDeletedAt: deletedAt},
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> deleteByDebtId(String debtId, String deletedAt,
      [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebtItems,
      {columnDeletedAt: deletedAt},
      where: '$columnDebtId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [debtId],
    );
  }
}
