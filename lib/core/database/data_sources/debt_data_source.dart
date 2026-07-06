import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';

class DebtDataSource {
  final Database db;

  DebtDataSource(this.db);

  Future<List<Map<String, dynamic>>> getAll({
    String? customerId,
    DebtStatus? status,
  }) async {
    final conditions = <String>['$columnDeletedAt IS NULL'];
    final args = <dynamic>[];

    if (customerId != null) {
      conditions.add('$columnCustomerId = ?');
      args.add(customerId);
    }
    if (status != null) {
      conditions.add('$columnStatus = ?');
      args.add(status.value);
    }

    return db.query(
      tableDebts,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: '$columnTransactionDate DESC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final results = await db.query(
      tableDebts,
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> map) async {
    await db.insert(tableDebts, map);
  }

  Future<void> update(Map<String, dynamic> map) async {
    await db.update(
      tableDebts,
      map,
      where: '$columnId = ?',
      whereArgs: [map[columnId]],
    );
  }

  Future<void> delete(String id, String deletedAt, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebts,
      {columnDeletedAt: deletedAt},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByCustomerId(
      String customerId, String deletedAt, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebts,
      {columnDeletedAt: deletedAt},
      where: '$columnCustomerId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [customerId],
    );
  }

  Future<double> sumSubtotalsByDebtId(String debtId, [Transaction? txn]) async {
    final conn = txn ?? db;
    final result = await conn.rawQuery(
      'SELECT COALESCE(SUM($columnSubtotal), 0) as total FROM $tableDebtItems WHERE $columnDebtId = ? AND $columnDeletedAt IS NULL',
      [debtId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> sumPaymentAmountsByDebtId(String debtId,
      [Transaction? txn]) async {
    final conn = txn ?? db;
    final result = await conn.rawQuery(
      'SELECT COALESCE(SUM($columnAmount), 0) as paid FROM $tablePayments WHERE $columnDebtId = ? AND $columnDeletedAt IS NULL',
      [debtId],
    );
    return (result.first['paid'] as num).toDouble();
  }

  Future<void> updateDebtTotals({
    required String debtId,
    required double totalAmount,
    required double paidAmount,
    required double balance,
    required String status,
    required String updatedAt,
    Transaction? txn,
  }) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebts,
      {
        columnTotalAmount: totalAmount,
        columnPaidAmount: paidAmount,
        columnBalance: balance,
        columnStatus: status,
        columnUpdatedAt: updatedAt,
      },
      where: '$columnId = ?',
      whereArgs: [debtId],
    );
  }

  Future<double> getPaidAmount(String debtId) async {
    final results = await db.query(
      tableDebts,
      columns: [columnPaidAmount],
      where: '$columnId = ?',
      whereArgs: [debtId],
    );
    return results.isNotEmpty
        ? (results.first[columnPaidAmount] as num).toDouble()
        : 0.0;
  }

  Future<double> getTotalAmount(String debtId) async {
    final results = await db.query(
      tableDebts,
      columns: [columnTotalAmount],
      where: '$columnId = ?',
      whereArgs: [debtId],
    );
    if (results.isEmpty) return 0.0;
    return (results.first[columnTotalAmount] as num).toDouble();
  }
}
