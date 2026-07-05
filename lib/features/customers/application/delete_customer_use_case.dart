import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';

class DeleteCustomerUseCase {
  final CustomerRepository _repository;

  DeleteCustomerUseCase(this._repository);

  Future<Result<void>> execute(String id) {
    return _repository.delete(id);
  }
}
