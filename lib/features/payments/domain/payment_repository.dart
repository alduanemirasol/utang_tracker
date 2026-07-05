import 'package:utang_tracker/core/errors/result.dart';
import 'payment.dart';

abstract class PaymentRepository {
  Future<Result<Payment>> create(Payment payment);
  Future<Result<List<Payment>>> getByDebtId(String debtId);
  Future<Result<Payment>> update(Payment payment);
  Future<Result<void>> delete(String id);
}
