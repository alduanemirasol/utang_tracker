import 'package:utang_tracker/core/database/tables.dart';
import 'package:utang_tracker/features/customers/domain/customer.dart';

class CustomerModel {
  final String id;
  final String name;
  final String? phone;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map[columnId] as String,
      name: map[columnName] as String,
      phone: map[columnPhone] as String?,
      notes: map[columnNotes] as String?,
      createdAt: map[columnCreatedAt] as String,
      updatedAt: map[columnUpdatedAt] as String,
      deletedAt: map[columnDeletedAt] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnName: name,
      columnPhone: phone,
      columnNotes: notes,
      columnCreatedAt: createdAt,
      columnUpdatedAt: updatedAt,
      columnDeletedAt: deletedAt,
    };
  }

  Customer toEntity() {
    return Customer(
      id: id,
      name: name,
      phone: phone,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      deletedAt: deletedAt != null ? DateTime.parse(deletedAt!) : null,
    );
  }

  factory CustomerModel.fromEntity(Customer entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      notes: entity.notes,
      createdAt: entity.createdAt.toUtc().toIso8601String(),
      updatedAt: entity.updatedAt.toUtc().toIso8601String(),
      deletedAt: entity.deletedAt?.toUtc().toIso8601String(),
    );
  }
}
