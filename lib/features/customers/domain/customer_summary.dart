import 'customer.dart';

class CustomerSummary {
  final Customer customer;
  final int totalDebts;
  final double totalBalance;
  final double totalPaid;
  final DateTime? lastTransactionDate;

  const CustomerSummary({
    required this.customer,
    required this.totalDebts,
    required this.totalBalance,
    required this.totalPaid,
    this.lastTransactionDate,
  });
}
