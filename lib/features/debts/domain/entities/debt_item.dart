import 'package:equatable/equatable.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';

class DebtItem extends Equatable {
  const DebtItem({
    required this.id,
    required this.debtId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.price,
  });

  final String id;
  final String debtId;
  final String productName;
  final double quantity;
  final String unit;
  final Money price;

  @override
  List<Object?> get props => [id, debtId, productName, quantity, unit, price];
}

/// Input for creating/editing a line item (id assigned by repository).
class DebtItemInput extends Equatable {
  const DebtItemInput({
    required this.productName,
    required this.quantity,
    this.unit = DebtItemUnits.piece,
    required this.price,
  });

  final String productName;
  final double quantity;
  final String unit;
  final Money price;

  @override
  List<Object?> get props => [productName, quantity, unit, price];
}
