import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/debts/domain/debt_repository.dart';

class GetDebtUseCase {
  final DebtRepository _repository;

  GetDebtUseCase(this._repository);

  Future<Result<Debt>> execute(String id) {
    return _repository.getById(id);
  }
}
