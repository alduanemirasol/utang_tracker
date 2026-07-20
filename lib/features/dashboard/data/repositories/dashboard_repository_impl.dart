import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/features/customers/domain/repositories/customer_repository.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';
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
    final data = await getDashboardData();
    return DashboardSummary(
      outstandingBalance: data.outstandingBalance,
      collectedToday: data.collectedToday,
      activeDebtsCount: data.activeDebtsCount,
      totalCustomers: data.totalCustomers,
      recentActivity: const [],
    );
  }

  @override
  Future<DashboardData> getDashboardData() async {
    final now = DateTime.now();
    final start = DateFormatters.startOfLocalDay(now);
    final end = DateFormatters.endOfLocalDay(now);

    final outstandingCentavos = await debts.outstandingBalanceCentavos();
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

    return DashboardData(
      outstandingBalance: Money.fromCentavos(outstandingCentavos),
      collectedToday: collectedToday,
      activeDebtsCount: activeDebts,
      totalCustomers: totalCustomers,
      recentDebts: recentDebts,
      recentPayments: recentPayments,
    );
  }
}
