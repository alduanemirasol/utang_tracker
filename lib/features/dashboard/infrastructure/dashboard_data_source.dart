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
      'SELECT COALESCE(SUM($columnPaidAmount), 0) as total FROM $tableDebts WHERE $columnDeletedAt IS NULL',
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

  Future<List<Map<String, dynamic>>> getRecentPayments({int limit = 5}) async {
    return db.rawQuery(
      'SELECT p.*, c.$columnName as customer_name FROM $tablePayments p '
      'INNER JOIN $tableDebts d ON p.$columnDebtId = d.$columnId '
      'INNER JOIN $tableCustomers c ON d.$columnCustomerId = c.$columnId '
      'WHERE p.$columnDeletedAt IS NULL AND d.$columnDeletedAt IS NULL AND c.$columnDeletedAt IS NULL '
      'ORDER BY p.$columnCreatedAt DESC '
      'LIMIT ?',
      [limit],
    );
  }
}
