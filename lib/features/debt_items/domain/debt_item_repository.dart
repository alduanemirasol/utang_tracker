import 'package:utang_tracker/core/errors/result.dart';
import 'debt_item.dart';

abstract class DebtItemRepository {
  Future<Result<DebtItem>> create(DebtItem item);
  Future<Result<List<DebtItem>>> getByDebtId(String debtId);
  Future<Result<DebtItem>> update(DebtItem item);
  Future<Result<void>> delete(String id);
}
