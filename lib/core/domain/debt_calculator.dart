class DebtCalculator {
  const DebtCalculator._();

  /// Floating-point tolerance for money comparisons.
  static const double epsilon = 0.001;

  static String calculateStatus({
    required double totalAmount,
    required double paidAmount,
  }) {
    final balance = calculateBalance(
      totalAmount: totalAmount,
      paidAmount: paidAmount,
    );
    if (balance <= epsilon) return 'PAID';
    if (paidAmount > epsilon) return 'PARTIAL';
    return 'UNPAID';
  }

  /// Remaining balance; never negative (overpayment keeps full paid history).
  static double calculateBalance({
    required double totalAmount,
    required double paidAmount,
  }) {
    final balance = totalAmount - paidAmount;
    return balance < 0 ? 0.0 : balance;
  }

  static bool exceedsBalance({
    required double amount,
    required double remainingBalance,
  }) {
    return amount > remainingBalance + epsilon;
  }
}
