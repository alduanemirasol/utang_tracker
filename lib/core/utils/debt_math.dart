import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';

class DebtMath {
  DebtMath._();

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
