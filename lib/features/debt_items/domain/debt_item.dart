class DebtItem {
  final String id;
  final String debtId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;

  const DebtItem({
    required this.id,
    required this.debtId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
  });

  DebtItem copyWith({
    String? id,
    String? debtId,
    String? productName,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? subtotal,
  }) {
    return DebtItem(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  double get calculatedSubtotal => quantity * unitPrice;
}
