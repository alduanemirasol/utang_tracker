import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/domain/debt_calculator.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';

class DebtDataSource {
  final Database db;

  DebtDataSource(this.db);

  Future<List<Map<String, dynamic>>> getAll({
    String? customerId,
    DebtStatus? status,
    Transaction? txn,
  }) async {
    final conn = txn ?? db;
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

    return conn.query(
      tableDebts,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: '$columnTransactionDate DESC',
    );
  }

  Future<Map<String, dynamic>?> getById(String id, [Transaction? txn]) async {
    final conn = txn ?? db;
    final results = await conn.query(
      tableDebts,
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insert(Map<String, dynamic> map, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.insert(tableDebts, map);
  }

  Future<void> update(Map<String, dynamic> map, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebts,
      map,
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [map[columnId]],
    );
  }

  Future<void> delete(String id, String deletedAt, [Transaction? txn]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebts,
      {
        columnDeletedAt: deletedAt,
        columnUpdatedAt: deletedAt,
      },
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [id],
    );
  }

  Future<void> deleteByCustomerId(
    String customerId,
    String deletedAt, [
    Transaction? txn,
  ]) async {
    final conn = txn ?? db;
    await conn.update(
      tableDebts,
      {
        columnDeletedAt: deletedAt,
        columnUpdatedAt: deletedAt,
      },
      where: '$columnCustomerId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [customerId],
    );
  }

  Future<double> sumSubtotalsByDebtId(
    String debtId, [
    Transaction? txn,
  ]) async {
    final conn = txn ?? db;
    final result = await conn.rawQuery(
      'SELECT COALESCE(SUM($columnSubtotal), 0) as total '
      'FROM $tableDebtItems '
      'WHERE $columnDebtId = ? AND $columnDeletedAt IS NULL',
      [debtId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> sumPaymentAmountsByDebtId(
    String debtId, [
    Transaction? txn,
  ]) async {
    final conn = txn ?? db;
    final result = await conn.rawQuery(
      'SELECT COALESCE(SUM($columnAmount), 0) as paid '
      'FROM $tablePayments '
      'WHERE $columnDebtId = ? AND $columnDeletedAt IS NULL',
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
      where: '$columnId = ? AND $columnDeletedAt IS NULL',
      whereArgs: [debtId],
    );
  }

  /// Single source of truth: total from items, paid from payments, inside [txn].
  Future<void> recalculateTotals(String debtId, Transaction txn) async {
    final totalAmount = await sumSubtotalsByDebtId(debtId, txn);
    final paidAmount = await sumPaymentAmountsByDebtId(debtId, txn);
    final balance = DebtCalculator.calculateBalance(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
    );
    final status = DebtCalculator.calculateStatus(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
    );
    final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
    await updateDebtTotals(
      debtId: debtId,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      balance: balance,
      status: status,
      updatedAt: now,
      txn: txn,
    );
  }
}
