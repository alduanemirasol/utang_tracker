import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/domain/debt_item.dart';

class DebtItemModel {
  final String id;
  final String debtId;
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final String? createdAt;
  final String? deletedAt;

  const DebtItemModel({
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

  factory DebtItemModel.fromMap(Map<String, dynamic> map) {
    return DebtItemModel(
      id: map[columnId] as String,
      debtId: map[columnDebtId] as String,
      productName: map[columnProductName] as String,
      quantity: (map[columnQuantity] as num).toDouble(),
      unit: map[columnUnit] as String,
      unitPrice: (map[columnUnitPrice] as num).toDouble(),
      subtotal: (map[columnSubtotal] as num).toDouble(),
      createdAt: map[columnCreatedAt] as String?,
      deletedAt: map[columnDeletedAt] as String?,
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
      columnCreatedAt: createdAt,
      columnDeletedAt: deletedAt,
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
      createdAt: createdAt != null ? DateTime.parse(createdAt!) : null,
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
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
      createdAt: entity.createdAt?.toUtc().toIso8601String(),
      deletedAt: entity.deletedAt?.toUtc().toIso8601String(),
    );
  }
}
