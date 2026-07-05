import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';

class CustomerDataSource {
  final Database db;

  CustomerDataSource(this.db);

  Future<List<Map<String, dynamic>>> getAll() async {
    return db.query(tableCustomers, orderBy: '$columnName ASC');
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final results = await db.query(
      tableCustomers,
      where: '$columnId = ?',
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
      where: '$columnId = ?',
      whereArgs: [map[columnId]],
    );
  }

  Future<void> delete(String id) async {
    await db.delete(
      tableCustomers,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
