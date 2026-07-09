class DebtItem {
  final String id;
  final String debtId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  const DebtItem({
    required this.id,
    required this.debtId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
    this.createdAt,
    this.deletedAt,
  });

  DebtItem copyWith({
    String? id,
    String? debtId,
    String? productName,
    double? quantity,
    String? unit,
    double? unitPrice,
    double? subtotal,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return DebtItem(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  double get calculatedSubtotal => quantity * unitPrice;
}
