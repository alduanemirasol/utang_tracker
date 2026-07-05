import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';
import 'package:utang_tracker/features/customers/domain/customer_summary.dart';

class GetCustomerSummaryUseCase {
  final CustomerRepository _repository;

  GetCustomerSummaryUseCase(this._repository);

  Future<Result<CustomerSummary>> execute(String id) {
    return _repository.getSummary(id);
  }
}
