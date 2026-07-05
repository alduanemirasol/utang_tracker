import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';

class DeleteDebtItemUseCase {
  final DebtItemRepository _repository;

  DeleteDebtItemUseCase(this._repository);

  Future<Result<void>> execute(String id) {
    return _repository.delete(id);
  }
}
