import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'debt_detail.dart';

abstract class DebtRepository {
  Future<Result<Debt>> create(Debt debt);
  Future<Result<List<Debt>>> getAll({String? customerId, DebtStatus? status});
  Future<Result<Debt>> getById(String id);
  Future<Result<DebtDetail>> getDetail(String id);
  Future<Result<Debt>> update(Debt debt);
  Future<Result<void>> delete(String id);
}
