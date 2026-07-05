import 'package:utang_tracker/core/errors/result.dart';
import 'debt.dart';

abstract class DebtRepository {
  Future<Result<Debt>> create(Debt debt);
  Future<Result<List<Debt>>> getAll({String? customerId});
  Future<Result<Debt>> getById(String id);
  Future<Result<Debt>> update(Debt debt);
  Future<Result<void>> delete(String id);
}
