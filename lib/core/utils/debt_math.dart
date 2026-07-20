import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';

/// Pure business math aligned with `rules/database_rules.md`.
class DebtMath {
  DebtMath._();

  /// Sum of custom item prices (quantity does not multiply).
  static Money computeTotal(Iterable<Money> prices) {
    var total = Money.zero();
    for (final price in prices) {
      total = total + price;
    }
    return total;
  }

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
