enum DebtStatus {
  unpaid,
  partial,
  paid;

  String get value {
    switch (this) {
      case DebtStatus.unpaid:
        return 'UNPAID';
      case DebtStatus.partial:
        return 'PARTIAL';
      case DebtStatus.paid:
        return 'PAID';
    }
  }

  static DebtStatus fromString(String value) {
    switch (value) {
      case 'UNPAID':
        return DebtStatus.unpaid;
      case 'PARTIAL':
        return DebtStatus.partial;
      case 'PAID':
        return DebtStatus.paid;
      default:
        throw ArgumentError('Invalid DebtStatus: $value');
    }
  }
}
