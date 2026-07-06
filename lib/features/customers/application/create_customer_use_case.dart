import 'package:uuid/uuid.dart';
import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';

const _uuid = Uuid();

class CreateCustomerUseCase {
  final CustomerRepository _repository;

  CreateCustomerUseCase(this._repository);

  Future<Result<Customer>> execute({
    required String name,
    String? phone,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      return Error(ValidationFailure('Name is required'));
    }

    final now = DateTimeHelper.createdAt();
    final customer = Customer(
      id: _uuid.v4(),
      name: name.trim(),
      phone: phone?.trim(),
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    return _repository.create(customer);
  }
}
