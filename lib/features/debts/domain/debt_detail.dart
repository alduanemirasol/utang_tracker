import 'debt.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item.dart';
import 'package:utang_tracker/features/payments/domain/payment.dart';

class DebtDetail {
  final Debt debt;
  final List<DebtItem> items;
  final List<Payment> payments;

  const DebtDetail({
    required this.debt,
    required this.items,
    required this.payments,
  });
}
