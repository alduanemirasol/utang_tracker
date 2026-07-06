String _addThousandSeparators(String intPart) {
  return intPart.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match.group(1)},',
  );
}

String formatAmount(double value) {
  final parts = value.toStringAsFixed(2).split('.');
  final intPart = _addThousandSeparators(parts[0]);
  final decimalPart = parts[1];
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value > 0 ? '∞' : '-∞';
  return '$intPart.$decimalPart';
}

String formatPeso(double value) {
  return '₱${formatAmount(value)}';
}

String formatQuantity(double value) {
  if (value.isNaN) return 'NaN';
  if (value.isInfinite) return value > 0 ? '∞' : '-∞';
  final parts = value.toStringAsFixed(2).split('.');
  final intPart = _addThousandSeparators(parts[0]);
  final decimalPart = parts[1];
  if (decimalPart == '00' || value == value.roundToDouble()) {
    return intPart;
  }
  return '$intPart.$decimalPart';
}
