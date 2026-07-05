import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item.dart';
import 'package:utang_tracker/features/debt_items/domain/debt_item_repository.dart';

class GetDebtItemUseCase {
  final DebtItemRepository _repository;

  GetDebtItemUseCase(this._repository);

  Future<Result<DebtItem>> execute(String id) {
    return _repository.getById(id);
  }
}
