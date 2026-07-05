import 'package:utang_tracker/core/errors/result.dart';
import 'customer.dart';
import 'customer_summary.dart';

abstract class CustomerRepository {
  Future<Result<Customer>> create(Customer customer);
  Future<Result<List<Customer>>> getAll({String? query});
  Future<Result<Customer>> getById(String id);
  Future<Result<CustomerSummary>> getSummary(String id);
  Future<Result<Customer>> update(Customer customer);
  Future<Result<void>> delete(String id);
}
