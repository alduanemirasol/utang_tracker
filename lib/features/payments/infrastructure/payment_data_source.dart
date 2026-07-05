import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';

class PaymentDataSource {
  final Database db;

  PaymentDataSource(this.db);

  Future<List<Map<String, dynamic>>> getByDebtId(String debtId) async {
    return db.query(
      tablePayments,
      where: '$columnDebtId = ?',
      whereArgs: [debtId],
      orderBy: '$columnPaymentDate DESC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final results = await db.query(
      tablePayments,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> map, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.insert(tablePayments, map);
  }

  Future<void> update(Map<String, dynamic> map, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tablePayments,
      map,
      where: '$columnId = ?',
      whereArgs: [map[columnId]],
    );
  }

  Future<void> delete(String id, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.delete(
      tablePayments,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}
