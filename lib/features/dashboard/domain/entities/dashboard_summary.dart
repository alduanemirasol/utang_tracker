import 'package:equatable/equatable.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';

class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.outstandingBalance,
    required this.collectedToday,
    required this.activeDebtsCount,
    required this.totalCustomers,
    required this.recentPayments,
    required this.recentDebts,
  });

  final Money outstandingBalance;
  final Money collectedToday;
  final int activeDebtsCount;
  final int totalCustomers;
  final List<Payment> recentPayments;
  final List<Debt> recentDebts;

  @override
  List<Object?> get props => [
        outstandingBalance,
        collectedToday,
        activeDebtsCount,
        totalCustomers,
        recentPayments,
        recentDebts,
      ];
}
