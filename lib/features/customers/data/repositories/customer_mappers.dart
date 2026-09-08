import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';

Customer mapCustomer(CustomerRow row) {
  return Customer(
    id: row.id,
    name: row.name,
    phone: row.phone,
    notes: row.notes,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
