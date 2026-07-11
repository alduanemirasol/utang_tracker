import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/customers/domain/repositories/customer_repository.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/recent_activity_item.dart';
import 'package:utang_tracker/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/payments/domain/repositories/payment_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required this.customers,
    required this.debts,
    required this.payments,
  });

  final CustomerRepository customers;
  final DebtRepository debts;
  final PaymentRepository payments;

  @override
  Future<DashboardSummary> getSummary() async {
    final now = DateTime.now();
    final start = DateFormatters.startOfLocalDay(now);
    final end = DateFormatters.endOfLocalDay(now);

    final outstanding = await debts.outstandingBalanceCentavos();
    final collectedToday = await payments.collectedBetween(
      start: start,
      end: end,
    );
    final activeDebts = await debts.countActive();
    final totalCustomers = await customers.count();
    final recentPayments = await payments.getRecent(
      limit: AppConstants.recentItemsLimit,
    );
    final recentDebts = await debts.getRecent(
      limit: AppConstants.recentItemsLimit,
    );

    final merged = <RecentActivityItem>[
      ...recentDebts.map(
        (d) => RecentActivityItem(
          type: RecentActivityType.debt,
          id: d.id,
          debtId: d.id,
          customerName: d.customerName ?? 'Customer',
          amount: d.totalAmount,
          date: d.createdAt,
        ),
      ),
      ...recentPayments.map(
        (p) => RecentActivityItem(
          type: RecentActivityType.payment,
          id: p.id,
          debtId: p.debtId,
          customerName: p.customerName ?? 'Customer',
          amount: p.amount,
          date: p.createdAt,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final recentActivity = merged
        .take(AppConstants.recentItemsLimit)
        .toList(growable: false);

    return DashboardSummary(
      outstandingBalance: Money.fromCentavos(outstanding),
      collectedToday: collectedToday,
      activeDebtsCount: activeDebts,
      totalCustomers: totalCustomers,
      recentActivity: recentActivity,
    );
  }
}
