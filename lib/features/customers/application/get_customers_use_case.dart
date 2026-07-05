import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';

class GetCustomersUseCase {
  final CustomerRepository _repository;

  GetCustomersUseCase(this._repository);

  Future<Result<List<Customer>>> execute() {
    return _repository.getAll();
  }
}
