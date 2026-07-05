import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item.dart';

class DebtItemModel {
  final String id;
  final String debtId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;

  const DebtItemModel({
    required this.id,
    required this.debtId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
  });

  factory DebtItemModel.fromMap(Map<String, dynamic> map) {
    return DebtItemModel(
      id: map[columnId] as String,
      debtId: map[columnDebtId] as String,
      productName: map[columnProductName] as String,
      quantity: (map[columnQuantity] as num).toDouble(),
      unit: map[columnUnit] as String,
      unitPrice: (map[columnUnitPrice] as num).toDouble(),
      subtotal: (map[columnSubtotal] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnDebtId: debtId,
      columnProductName: productName,
      columnQuantity: quantity,
      columnUnit: unit,
      columnUnitPrice: unitPrice,
      columnSubtotal: subtotal,
    };
  }

  DebtItem toEntity() {
    return DebtItem(
      id: id,
      debtId: debtId,
      productName: productName,
      quantity: quantity,
      unit: unit,
      unitPrice: unitPrice,
      subtotal: subtotal,
    );
  }

  factory DebtItemModel.fromEntity(DebtItem entity) {
    return DebtItemModel(
      id: entity.id,
      debtId: entity.debtId,
      productName: entity.productName,
      quantity: entity.quantity,
      unit: entity.unit,
      unitPrice: entity.unitPrice,
      subtotal: entity.subtotal,
    );
  }
}
