import 'package:utang_tracker/features/debts/domain/debt.dart';
import 'package:utang_tracker/features/payments/domain/payment.dart';

class DashboardSummary {
  final double totalOutstandingBalance;
  final double totalCollected;
  final int activeDebtCount;
  final int totalCustomers;
  final List<Debt> recentDebts;
  final List<Payment> recentPayments;

  const DashboardSummary({
    required this.totalOutstandingBalance,
    required this.totalCollected,
    required this.activeDebtCount,
    required this.totalCustomers,
    required this.recentDebts,
    required this.recentPayments,
  });
}
