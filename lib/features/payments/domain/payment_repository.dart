import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/errors/result.dart';

abstract class PaymentRepository {
  Future<Result<Payment>> create(Payment payment);
  Future<Result<Payment>> getById(String id);
  Future<Result<List<Payment>>> getByDebtId(String debtId);
  Future<Result<Payment>> update(Payment payment);
  Future<Result<void>> delete(String id);
}
