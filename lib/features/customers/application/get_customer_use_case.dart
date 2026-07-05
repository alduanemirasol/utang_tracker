import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';

class GetCustomerUseCase {
  final CustomerRepository _repository;

  GetCustomerUseCase(this._repository);

  Future<Result<Customer>> execute(String id) {
    return _repository.getById(id);
  }
}
