import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';

/// Pure business math aligned with `rules/database_rules.md`.
class DebtMath {
  DebtMath._();

  /// subtotal = quantity × unit_price
  static Money computeSubtotal({
    required double quantity,
    required Money unitPrice,
  }) {
    return Money.subtotal(quantity: quantity, unitPrice: unitPrice);
  }

  /// total_amount = sum of item subtotals
  static Money computeTotal(Iterable<Money> subtotals) {
    var total = Money.zero();
    for (final s in subtotals) {
      total = total + s;
    }
    return total;
  }

  /// balance = total_amount − paid_amount
  static Money computeBalance({
    required Money totalAmount,
    required Money paidAmount,
  }) {
    return totalAmount - paidAmount;
  }

  /// Status derivation (documented assumption when paid vs total).
  static DebtStatus deriveStatus({
    required Money totalAmount,
    required Money paidAmount,
  }) {
    if (paidAmount.centavos <= 0) {
      return DebtStatus.unpaid;
    }
    if (paidAmount.centavos >= totalAmount.centavos) {
      return DebtStatus.paid;
    }
    return DebtStatus.partial;
  }
}
