import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';

class CustomerDataSource {
  final Database db;

  CustomerDataSource(this.db);

  Future<List<Map<String, dynamic>>> getAll({String? query}) async {
    if (query != null && query.isNotEmpty) {
      return db.query(
        tableCustomers,
        where: '$columnDeletedAt IS NULL AND $columnName LIKE ?',
        whereArgs: ['%$query%'],
        orderBy: '$columnName ASC',
      );
    }
    return db.query(
      tableCustomers,
      where: '$columnDeletedAt IS NULL',
      orderBy: '$columnName ASC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id, [Transaction? txn]) async {
    final conn = txn ?? db;
    final results = await conn.query(
      tableCustomers,
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> map) async {
    await db.insert(tableCustomers, map);
  }

  Future<void> update(Map<String, dynamic> map) async {
    await db.update(
      tableCustomers,
      map,
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [map[columnId]],
    );
  }

  Future<void> delete(String id, String deletedAt, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableCustomers,
      {
        columnDeletedAt: deletedAt,
        columnUpdatedAt: deletedAt,
      },
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [id],
    );
  }
}
