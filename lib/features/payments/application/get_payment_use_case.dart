import 'package:utang_tracker/core/domain/payment.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';

class GetPaymentUseCase {
  final PaymentRepository _repository;

  GetPaymentUseCase(this._repository);

  Future<Result<Payment>> execute(String id) {
    return _repository.getById(id);
  }
}
