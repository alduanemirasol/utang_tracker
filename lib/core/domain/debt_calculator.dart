class DebtCalculator {
  const DebtCalculator._();

  static String calculateStatus({
    required double totalAmount,
    required double paidAmount,
  }) {
    final balance = totalAmount - paidAmount;
    if (balance <= 0) return 'PAID';
    if (paidAmount > 0) return 'PARTIAL';
    return 'UNPAID';
  }

  static double calculateBalance({
    required double totalAmount,
    required double paidAmount,
  }) {
    return totalAmount - paidAmount;
  }
}
