import 'package:utang_tracker/core/errors/result.dart';
import 'customer.dart';

abstract class CustomerRepository {
  Future<Result<Customer>> create(Customer customer);
  Future<Result<List<Customer>>> getAll({String? query});
  Future<Result<Customer>> getById(String id);
  Future<Result<List<Map<String, dynamic>>>> getDebtsByCustomerId(
      String customerId);
  Future<Result<Customer>> update(Customer customer);
  Future<Result<void>> delete(String id);
}
