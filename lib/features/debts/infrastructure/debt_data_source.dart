import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/helpers/date_time_helper.dart';

class DebtDataSource {
  final Database db;

  DebtDataSource(this.db);

  Future<List<Map<String, dynamic>>> getAll({String? customerId}) async {
    if (customerId != null) {
      return db.query(
        tableDebts,
        where: '$columnCustomerId = ?',
        whereArgs: [customerId],
        orderBy: '$columnTransactionDate DESC',
      );
    }
    return db.query(tableDebts, orderBy: '$columnTransactionDate DESC');
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final results = await db.query(
      tableDebts,
      where: '$columnId = ?',
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

  Future<void> delete(String id) async {
    await db.delete(
      tableDebts,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> recalculateFromItems(String debtId, [Transaction? txn]) async {
    final conn = txn ?? db;

    final itemResult = await conn.rawQuery(
      'SELECT COALESCE(SUM($columnSubtotal), 0) as total FROM $tableDebtItems WHERE $columnDebtId = ?',
      [debtId],
    );
    final totalAmount = (itemResult.first['total'] as num).toDouble();

    final debtResult = await conn.query(
      tableDebts,
      columns: [columnPaidAmount],
      where: '$columnId = ?',
      whereArgs: [debtId],
    );
    final paidAmount = debtResult.isNotEmpty
        ? (debtResult.first[columnPaidAmount] as num).toDouble()
        : 0.0;

    final balance = totalAmount - paidAmount;

    String status;
    if (balance <= 0) {
      status = 'PAID';
    } else if (paidAmount > 0) {
      status = 'PARTIAL';
    } else {
      status = 'UNPAID';
    }

    await conn.update(
      tableDebts,
      {
        columnTotalAmount: totalAmount,
        columnBalance: balance,
        columnStatus: status,
        columnUpdatedAt: DateTimeHelper.updatedAt().toUtc().toIso8601String(),
      },
      where: '$columnId = ?',
      whereArgs: [debtId],
    );
  }

  Future<void> recalculateFromPayments(String debtId,
      [Transaction? txn]) async {
    final conn = txn ?? db;

    final paymentResult = await conn.rawQuery(
      'SELECT COALESCE(SUM($columnAmount), 0) as paid FROM $tablePayments WHERE $columnDebtId = ?',
      [debtId],
    );
    final paidAmount = (paymentResult.first['paid'] as num).toDouble();

    final debtResult = await conn.query(
      tableDebts,
      columns: [columnTotalAmount],
      where: '$columnId = ?',
      whereArgs: [debtId],
    );
    if (debtResult.isEmpty) return;
    final totalAmount = (debtResult.first[columnTotalAmount] as num).toDouble();
    final balance = totalAmount - paidAmount;

    String status;
    if (balance <= 0) {
      status = 'PAID';
    } else if (paidAmount > 0) {
      status = 'PARTIAL';
    } else {
      status = 'UNPAID';
    }

    await conn.update(
      tableDebts,
      {
        columnPaidAmount: paidAmount,
        columnBalance: balance,
        columnStatus: status,
        columnUpdatedAt: DateTimeHelper.updatedAt().toUtc().toIso8601String(),
      },
      where: '$columnId = ?',
      whereArgs: [debtId],
    );
  }
}
