import 'package:sqflite/sqflite.dart';
import 'package:utang_tracker/core/database/data_sources/debt_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/debt_item_data_source.dart';
import 'package:utang_tracker/core/database/data_sources/payment_data_source.dart';
import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';
import 'package:utang_tracker/features/customers/infrastructure/customer_data_source.dart';
import 'package:utang_tracker/features/customers/infrastructure/customer_model.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerDataSource _customerDataSource;
  final DebtDataSource _debtDataSource;
  final DebtItemDataSource _debtItemDataSource;
  final PaymentDataSource _paymentDataSource;
  final Database _db;

  CustomerRepositoryImpl(
    this._customerDataSource,
    this._debtDataSource,
    this._debtItemDataSource,
    this._paymentDataSource,
    this._db,
  );

  @override
  Future<Result<Customer>> create(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await _customerDataSource.insert(model.toMap());
      return Success(customer);
    } catch (e) {
      return Error(DatabaseFailure('Failed to create customer: $e'));
    }
  }

  @override
  Future<Result<List<Customer>>> getAll({String? query}) async {
    try {
      final maps = await _customerDataSource.getAll(query: query);
      final customers = maps
          .map((m) => CustomerModel.fromMap(m).toEntity())
          .toList();
      return Success(customers);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load customers: $e'));
    }
  }

  @override
  Future<Result<Customer>> getById(String id) async {
    try {
      final map = await _customerDataSource.getById(id);
      if (map == null) {
        return Error(NotFoundFailure('Customer not found'));
      }
      return Success(CustomerModel.fromMap(map).toEntity());
    } catch (e) {
      return Error(DatabaseFailure('Failed to load customer: $e'));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDebtsByCustomerId(
    String customerId,
  ) async {
    try {
      final debtMaps = await _debtDataSource.getAll(customerId: customerId);
      return Success(debtMaps);
    } catch (e) {
      return Error(DatabaseFailure('Failed to load debts: $e'));
    }
  }

  @override
  Future<Result<Customer>> update(Customer customer) async {
    try {
      final model = CustomerModel.fromEntity(customer);
      await _customerDataSource.update(model.toMap());
      return Success(customer);
    } catch (e) {
      return Error(DatabaseFailure('Failed to update customer: $e'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.transaction((txn) async {
        final now = DateTimeHelper.updatedAt().toUtc().toIso8601String();
        final debtMaps = await _debtDataSource.getAll(customerId: id);
        for (final map in debtMaps) {
          final debtId = map[columnId] as String;
          await _paymentDataSource.deleteByDebtId(debtId, now, txn);
          await _debtItemDataSource.deleteByDebtId(debtId, now, txn);
        }
        await _debtDataSource.deleteByCustomerId(id, now, txn);
        await _customerDataSource.delete(id, now, txn);
      });
      return const Success(null);
    } catch (e) {
      return Error(DatabaseFailure('Failed to delete customer: $e'));
    }
  }
}
