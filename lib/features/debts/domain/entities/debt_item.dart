import 'package:equatable/equatable.dart';
import 'package:utang_tracker/core/utils/money.dart';

class DebtItem extends Equatable {
  const DebtItem({
    required this.id,
    required this.debtId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String id;
  final String debtId;
  final String productName;
  final double quantity;
  final Money unitPrice;
  final Money subtotal;

  @override
  List<Object?> get props => [
    id,
    debtId,
    productName,
    quantity,
    unitPrice,
    subtotal,
  ];
}

/// Input for creating/editing a line item (id assigned by repository).
class DebtItemInput extends Equatable {
  const DebtItemInput({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productName;
  final double quantity;
  final Money unitPrice;

  @override
  List<Object?> get props => [productName, quantity, unitPrice];
}
