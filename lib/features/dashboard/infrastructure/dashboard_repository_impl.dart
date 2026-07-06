import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/dashboard/domain/activity_item.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_repository.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/infrastructure/dashboard_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardDataSource _dataSource;

  DashboardRepositoryImpl(this._dataSource);

  @override
  Future<Result<DashboardSummary>> getSummary() async {
    try {
      final results = await Future.wait([
        _dataSource.getTotalOutstandingBalance(),
        _dataSource.getTotalCollected(),
        _dataSource.getActiveDebtCount(),
        _dataSource.getTotalCustomers(),
        _dataSource.getRecentDebts(),
        _dataSource.getRecentPayments(),
      ]);

      final debtMaps = results[4] as List<Map<String, dynamic>>;
      final paymentMaps = results[5] as List<Map<String, dynamic>>;

      final debtItems = debtMaps.map((m) {
        return ActivityItem(
          id: m['id'] as String,
          type: ActivityType.debt,
          customerName: m['customer_name'] as String,
          amount: (m['total_amount'] as num).toDouble(),
          date: DateTime.parse(m['created_at'] as String),
          statusLabel: _debtStatusLabel(m['status'] as String),
        );
      });

      final paymentItems = paymentMaps.map((m) {
        return ActivityItem(
          id: m['id'] as String,
          type: ActivityType.payment,
          customerName: m['customer_name'] as String,
          amount: (m['amount'] as num).toDouble(),
          date: DateTime.parse(m['created_at'] as String),
          statusLabel: _paymentMethodLabel(m['payment_method'] as String),
        );
      });

      final merged = [...debtItems, ...paymentItems];
      merged.sort((a, b) => b.date.compareTo(a.date));

      final summary = DashboardSummary(
        totalOutstandingBalance: results[0] as double,
        totalCollected: results[1] as double,
        activeDebtCount: results[2] as int,
        totalCustomers: results[3] as int,
        recentActivity: merged,
      );

      return Success(summary);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load dashboard: $e'));
    }
  }

  String _debtStatusLabel(String status) {
    switch (status) {
      case 'PAID':
        return 'Paid';
      case 'PARTIAL':
        return 'Partial';
      default:
        return 'Unpaid';
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'GCASH':
        return 'GCash';
      case 'MAYA':
        return 'Maya';
      default:
        return 'Cash';
    }
  }
}
