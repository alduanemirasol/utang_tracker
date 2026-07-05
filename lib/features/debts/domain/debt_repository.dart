import 'package:utang_tracker/core/errors/result.dart';
import 'debt.dart';
import 'debt_detail.dart';
import 'debt_status.dart';

abstract class DebtRepository {
  Future<Result<Debt>> create(Debt debt);
  Future<Result<List<Debt>>> getAll({String? customerId, DebtStatus? status});
  Future<Result<Debt>> getById(String id);
  Future<Result<DebtDetail>> getDetail(String id);
  Future<Result<Debt>> update(Debt debt);
  Future<Result<void>> delete(String id);
}
