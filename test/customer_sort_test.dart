import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer_sort_order.dart';
import 'package:utang_tracker/features/customers/domain/usecases/customer_usecases.dart';

Customer _customer({
  required String id,
  required String name,
  required DateTime createdAt,
}) {
  return Customer(
    id: id,
    name: name,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

void main() {
  final customers = [
    _customer(
      id: 'bob',
      name: 'bob',
      createdAt: DateTime(2026, 3, 1),
    ),
    _customer(
      id: 'ana',
      name: 'Ana',
      createdAt: DateTime(2026, 1, 1),
    ),
    _customer(
      id: 'carl',
      name: 'Carl',
      createdAt: DateTime(2026, 2, 1),
    ),
  ];

  test('nameAsc sorts by name ascending case-insensitively', () {
    final sorted = applyCustomerSort(customers, CustomerSortOrder.nameAsc);
    expect(sorted.map((c) => c.id), ['ana', 'bob', 'carl']);
  });

  test('nameDesc sorts by name descending case-insensitively', () {
    final sorted = applyCustomerSort(customers, CustomerSortOrder.nameDesc);
    expect(sorted.map((c) => c.id), ['carl', 'bob', 'ana']);
  });

  test('newest sorts by createdAt desc', () {
    final sorted = applyCustomerSort(customers, CustomerSortOrder.newest);
    expect(sorted.map((c) => c.id), ['bob', 'carl', 'ana']);
  });

  test('oldest sorts by createdAt asc', () {
    final sorted = applyCustomerSort(customers, CustomerSortOrder.oldest);
    expect(sorted.map((c) => c.id), ['ana', 'carl', 'bob']);
  });

  test('does not mutate the input list', () {
    final before = customers.map((c) => c.id).toList();
    applyCustomerSort(customers, CustomerSortOrder.nameDesc);
    expect(customers.map((c) => c.id), before);
  });
}