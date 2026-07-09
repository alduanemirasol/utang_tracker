import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/tables.dart';

class DashboardDataSource {
  final Database db;

  DashboardDataSource(this.db);

  Future<double> getTotalOutstandingBalance() async {
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM($columnBalance), 0) as total FROM $tableDebts WHERE $columnStatus != ? AND $columnDeletedAt IS NULL',
      ['PAID'],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalCollected() async {
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(p.$columnAmount), 0) as total '
      'FROM $tablePayments p '
      'INNER JOIN $tableDebts d ON p.$columnDebtId = d.$columnId '
      'WHERE p.$columnDeletedAt IS NULL AND d.$columnDeletedAt IS NULL',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalDebtAmount() async {
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM($columnTotalAmount), 0) as total FROM $tableDebts WHERE $columnDeletedAt IS NULL',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> getActiveDebtCount() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableDebts WHERE $columnStatus != ? AND $columnDeletedAt IS NULL',
      ['PAID'],
    );
    return (result.first['count'] as int);
  }

  Future<int> getTotalCustomers() async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableCustomers WHERE $columnDeletedAt IS NULL',
    );
    return (result.first['count'] as int);
  }

  Future<Map<String, Object?>> getOverdueSummary(String todayIso) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count, COALESCE(SUM($columnBalance), 0) as amount '
      'FROM $tableDebts '
      'WHERE $columnDeletedAt IS NULL '
      'AND $columnStatus != ? '
      'AND $columnBalance > 0 '
      'AND $columnDueDate IS NOT NULL '
      'AND date($columnDueDate) < date(?)',
      ['PAID', todayIso],
    );
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getUpcomingDues({
    required String todayIso,
    int limit = 5,
  }) async {
    return db.rawQuery(
      'SELECT d.$columnId, d.$columnBalance, d.$columnDueDate, '
      'c.$columnName as customer_name '
      'FROM $tableDebts d '
      'INNER JOIN $tableCustomers c ON d.$columnCustomerId = c.$columnId '
      'WHERE d.$columnDeletedAt IS NULL '
      'AND c.$columnDeletedAt IS NULL '
      'AND d.$columnStatus != ? '
      'AND d.$columnBalance > 0 '
      'AND d.$columnDueDate IS NOT NULL '
      'AND date(d.$columnDueDate) >= date(?) '
      'ORDER BY d.$columnDueDate ASC '
      'LIMIT ?',
      ['PAID', todayIso, limit],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentDebts({int limit = 5}) async {
    return db.rawQuery(
      'SELECT d.*, c.$columnName as customer_name FROM $tableDebts d '
      'INNER JOIN $tableCustomers c ON d.$columnCustomerId = c.$columnId '
      'WHERE d.$columnDeletedAt IS NULL AND c.$columnDeletedAt IS NULL '
      'ORDER BY d.$columnCreatedAt DESC '
      'LIMIT ?',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getRecentPayments({int limit = 8}) async {
    return db.rawQuery(
      'SELECT p.*, d.$columnId as debt_id, c.$columnName as customer_name '
      'FROM $tablePayments p '
      'INNER JOIN $tableDebts d ON p.$columnDebtId = d.$columnId '
      'INNER JOIN $tableCustomers c ON d.$columnCustomerId = c.$columnId '
      'WHERE p.$columnDeletedAt IS NULL AND d.$columnDeletedAt IS NULL AND c.$columnDeletedAt IS NULL '
      'ORDER BY p.$columnCreatedAt DESC '
      'LIMIT ?',
      [limit],
    );
  }
}
