import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/recent_activity_item.dart';
import 'package:utang_tracker/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardSummary {
  const GetDashboardSummary(this._repository);
  final DashboardRepository _repository;

  Future<DashboardSummary> call() async {
    final data = await _repository.getDashboardData();

    final merged = <RecentActivityItem>[
      ...data.recentDebts.map(
        (d) => RecentActivityItem(
          type: RecentActivityType.debt,
          id: d.id,
          debtId: d.id,
          customerName: d.customerName ?? 'Customer',
          amount: d.totalAmount,
          date: d.createdAt,
        ),
      ),
      ...data.recentPayments.map(
        (p) => RecentActivityItem(
          type: RecentActivityType.payment,
          id: p.id,
          debtId: p.debtId,
          customerName: p.customerName ?? 'Customer',
          amount: p.amount,
          date: p.createdAt,
          paymentMethod: p.paymentMethod,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final recentActivity = merged
        .take(AppConstants.recentItemsLimit)
        .toList(growable: false);

    return DashboardSummary(
      outstandingBalance: data.outstandingBalance,
      collectedToday: data.collectedToday,
      activeDebtsCount: data.activeDebtsCount,
      totalCustomers: data.totalCustomers,
      recentActivity: recentActivity,
    );
  }
}
