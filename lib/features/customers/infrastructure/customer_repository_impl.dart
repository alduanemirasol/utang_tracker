import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';
import 'package:utang_tracker/features/customers/infrastructure/customer_data_source.dart';
import 'package:utang_tracker/features/customers/infrastructure/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerDataSource _dataSource;

  CustomerRepositoryImpl(this._dataSource);

  @override
  Future<Result<Customer>> create(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await _dataSource.insert(model.toMap());
      return Success(customer);
    } catch (e) {
      return Error(DatabaseFailure('Failed to create customer: $e'));
    }
  }

  @override
  Future<Result<List<Customer>>> getAll() async {
    try {
      final maps = await _dataSource.getAll();
      final customers = maps.map((m) => CustomerModel.fromMap(m).toEntity()).toList();
      return Success(customers);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load customers: $e'));
    }
  }

  @override
  Future<Result<Customer>> getById(String id) async {
    try {
      final map = await _dataSource.getById(id);
      if (map == null) {
        return Error(NotFoundFailure('Customer not found'));
      }
      return Success(CustomerModel.fromMap(map).toEntity());
    } catch (e) {
      return Error(DatabaseFailure('Failed to load customer: $e'));
    }
  }

  @override
  Future<Result<Customer>> update(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await _dataSource.update(model.toMap());
      return Success(customer);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update customer: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _dataSource.delete(id);
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete customer: $e'));
    }
  }
}
