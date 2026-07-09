import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
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
      final today = DateTimeHelper.nowPH();
      final todayIso =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';

      final results = await Future.wait([
        _dataSource.getTotalOutstandingBalance(),
        _dataSource.getTotalCollected(),
        _dataSource.getTotalDebtAmount(),
        _dataSource.getActiveDebtCount(),
        _dataSource.getTotalCustomers(),
        _dataSource.getOverdueSummary(todayIso),
        _dataSource.getUpcomingDues(todayIso: todayIso),
        _dataSource.getRecentDebts(),
        _dataSource.getRecentPayments(),
      ]);

      final overdueMap = results[5] as Map<String, Object?>;
      final upcomingMaps = results[6] as List<Map<String, dynamic>>;
      final debtMaps = results[7] as List<Map<String, dynamic>>;
      final paymentMaps = results[8] as List<Map<String, dynamic>>;

      final upcomingDues = upcomingMaps.map((m) {
        return UpcomingDueItem(
          debtId: m['id'] as String,
          customerName: m['customer_name'] as String,
          balance: (m['balance'] as num).toDouble(),
          dueDate: DateTime.parse(m['due_date'] as String),
        );
      }).toList();

      final debtItems = debtMaps.map((m) {
        return ActivityItem(
          id: m['id'] as String,
          debtId: m['id'] as String,
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
          debtId: m['debt_id'] as String,
          type: ActivityType.payment,
          customerName: m['customer_name'] as String,
          amount: (m['amount'] as num).toDouble(),
          date: DateTime.parse(m['created_at'] as String),
          statusLabel: _paymentMethodLabel(m['payment_method'] as String),
        );
      }).toList();

      final merged = [...debtItems, ...paymentItems];
      merged.sort((a, b) => b.date.compareTo(a.date));

      final summary = DashboardSummary(
        totalOutstandingBalance: results[0] as double,
        totalCollected: results[1] as double,
        totalDebtAmount: results[2] as double,
        activeDebtCount: results[3] as int,
        totalCustomers: results[4] as int,
        overdueCount: (overdueMap['count'] as num).toInt(),
        overdueAmount: (overdueMap['amount'] as num).toDouble(),
        upcomingDues: upcomingDues,
        recentPayments: paymentItems,
        recentActivity: merged.take(10).toList(),
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
