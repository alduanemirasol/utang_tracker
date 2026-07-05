import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_repository.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/infrastructure/dashboard_data_source.dart';
import 'package:utang_tracker/features/debts/infrastructure/debt_model.dart';
import 'package:utang_tracker/features/payments/infrastructure/payment_model.dart';

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

      final summary = DashboardSummary(
        totalOutstandingBalance: results[0] as double,
        totalCollected: results[1] as double,
        activeDebtCount: results[2] as int,
        totalCustomers: results[3] as int,
        recentDebts: (results[4] as List)
            .map((m) => DebtModel.fromMap(m).toEntity())
            .toList(),
        recentPayments: (results[5] as List)
            .map((m) => PaymentModel.fromMap(m).toEntity())
            .toList(),
      );

      return Success(summary);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load dashboard: $e'));
    }
  }
}
