import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';

class GetDebtItemsUseCase {
  final DebtItemRepository _repository;

  GetDebtItemsUseCase(this._repository);

  Future<Result<List<DebtItem>>> execute(String debtId) {
    return _repository.getByDebtId(debtId);
  }
}
