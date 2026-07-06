enum PaymentMethod {
  cash,
  gcash,
  maya;

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.gcash:
        return 'GCASH';
      case PaymentMethod.maya:
        return 'MAYA';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'CASH':
        return PaymentMethod.cash;
      case 'GCASH':
        return PaymentMethod.gcash;
      case 'MAYA':
        return PaymentMethod.maya;
      default:
        throw ArgumentError('Invalid PaymentMethod: $value');
    }
  }
}
