import 'package:uuid/uuid.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';

const _uuid = Uuid();

class CreateDebtItemUseCase {
  final DebtItemRepository _repository;

  CreateDebtItemUseCase(this._repository);

  Future<Result<DebtItem>> execute({
    required String debtId,
    required String productName,
    required double quantity,
    required String unit,
    required double unitPrice,
  }) async {
    if (productName.trim().isEmpty) {
      return Error(ValidationFailure('Product name is required'));
    }
    if (quantity <= 0) {
      return Error(ValidationFailure('Quantity must be greater than 0'));
    }
    if (unitPrice < 0) {
      return Error(ValidationFailure('Unit price cannot be negative'));
    }

    final subtotal = quantity * unitPrice;
    final item = DebtItem(
      id: _uuid.v4(),
      debtId: debtId,
      productName: productName.trim(),
      quantity: quantity,
      unit: unit.trim(),
      unitPrice: unitPrice,
      subtotal: subtotal,
    );

    return _repository.create(item);
  }
}
