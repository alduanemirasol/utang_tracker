import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/repositories/customer_repository.dart';

class GetCustomers {
  const GetCustomers(this._repository);
  final CustomerRepository _repository;
  Future<List<Customer>> call() => _repository.getAll();
}

class SearchCustomers {
  const SearchCustomers(this._repository);
  final CustomerRepository _repository;
  Future<List<Customer>> call(String query) => _repository.search(query);
}

class GetCustomerById {
  const GetCustomerById(this._repository);
  final CustomerRepository _repository;
  Future<Customer?> call(String id) => _repository.getById(id);
}

class CreateCustomer {
  const CreateCustomer(this._repository);
  final CustomerRepository _repository;
  Future<Customer> call({required String name, String? phone, String? notes}) {
    return _repository.create(name: name, phone: phone, notes: notes);
  }
}

class UpdateCustomer {
  const UpdateCustomer(this._repository);
  final CustomerRepository _repository;
  Future<Customer> call(Customer customer) => _repository.update(customer);
}

class DeleteCustomer {
  const DeleteCustomer(this._repository);
  final CustomerRepository _repository;
  Future<void> call(String id) => _repository.delete(id);
}
