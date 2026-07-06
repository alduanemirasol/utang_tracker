import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';

class GetPaymentsUseCase {
  final PaymentRepository _repository;

  GetPaymentsUseCase(this._repository);

  Future<Result<List<Payment>>> execute(String debtId) {
    return _repository.getByDebtId(debtId);
  }
}
