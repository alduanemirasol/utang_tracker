import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';

class DashboardData {
  const DashboardData({
    required this.outstandingBalance,
    required this.collectedToday,
    required this.activeDebtsCount,
    required this.totalCustomers,
    required this.recentDebts,
    required this.recentPayments,
  });

  final Money outstandingBalance;
  final Money collectedToday;
  final int activeDebtsCount;
  final int totalCustomers;
  final List<Debt> recentDebts;
  final List<Payment> recentPayments;
}
