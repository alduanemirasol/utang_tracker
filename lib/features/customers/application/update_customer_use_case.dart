import 'package:utang_tracker/core/errors/failure.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';
import 'package:utang_tracker/features/customers/domain/customer_repository.dart';

class UpdateCustomerUseCase {
  final CustomerRepository _repository;

  UpdateCustomerUseCase(this._repository);

  Future<Result<Customer>> execute({
    required String id,
    required String name,
    String? phone,
    String? notes,
  }) async {
    if (name.trim().isEmpty) {
      return Error(ValidationFailure('Name is required'));
    }

    final existing = await _repository.getById(id);
    switch (existing) {
      case Success():
        final trimmedPhone = phone?.trim();
        final trimmedNotes = notes?.trim();
        final updated = existing.data.copyWith(
          name: name.trim(),
          phone: trimmedPhone,
          notes: trimmedNotes,
          updatedAt: DateTimeHelper.updatedAt(),
          clearPhone: trimmedPhone == null || trimmedPhone.isEmpty,
          clearNotes: trimmedNotes == null || trimmedNotes.isEmpty,
        );
        return _repository.update(updated);
      case Error():
        return existing;
    }
  }
}
