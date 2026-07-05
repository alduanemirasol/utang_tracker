import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debts/domain/debt_detail.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';

class GetDebtDetailUseCase {
  final DebtRepository _repository;

  GetDebtDetailUseCase(this._repository);

  Future<Result<DebtDetail>> execute(String id) {
    return _repository.getDetail(id);
  }
}
