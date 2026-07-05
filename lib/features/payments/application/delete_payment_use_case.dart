import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/payments/domain/payment_repository.dart';

class DeletePaymentUseCase {
  final PaymentRepository _repository;

  DeletePaymentUseCase(this._repository);

  Future<Result<void>> execute(String id) {
    return _repository.delete(id);
  }
}
