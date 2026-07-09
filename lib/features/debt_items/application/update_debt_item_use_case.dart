import 'package:utang_tracker/core/domain/debt_item.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';

class UpdateDebtItemUseCase {
  final DebtItemRepository _repository;

  UpdateDebtItemUseCase(this._repository);

  Future<Result<DebtItem>> execute({
    required String id,
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
    if (unit.trim().isEmpty) {
      return Error(ValidationFailure('Unit is required'));
    }
    if (unitPrice < 0) {
      return Error(ValidationFailure('Unit price cannot be negative'));
    }

    final subtotal = quantity * unitPrice;
    final item = DebtItem(
      id: id,
      debtId: '',
      productName: productName.trim(),
      quantity: quantity,
      unit: unit.trim(),
      unitPrice: unitPrice,
      subtotal: subtotal,
    );

    return _repository.update(item);
  }
}
