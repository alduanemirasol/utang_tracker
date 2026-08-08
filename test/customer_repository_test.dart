import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/customers/domain/entities/customer.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';

void main() {
  late AppDatabase db;
  late CustomerRepositoryImpl customers;
  late DebtRepositoryImpl debts;

  setUp(() {
    db = AppDatabase.forTesting();
    customers = CustomerRepositoryImpl(db);
    debts = DebtRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create requires a non-empty name', () {
    expect(
      () => customers.create(name: '  '),
      throwsA(isA<ValidationException>()),
    );
  });

  test('create rejects case-insensitive duplicate names', () async {
    await customers.create(name: 'Juan dela Cruz');

    expect(
      () => customers.create(name: 'juan DELA cruz'),
      throwsA(isA<ConflictException>()),
    );
  });

  test('update rejects duplicates but allows renaming a customer', () async {
    final a = await customers.create(name: 'AAA');
    final b = await customers.create(name: 'BBB');

    expect(
      () => customers.update(
        Customer(
          id: b.id,
          name: '  aaa ',
          createdAt: b.createdAt,
          updatedAt: b.updatedAt,
        ),
      ),
      throwsA(isA<ConflictException>()),
    );

    final updatedA = await customers.update(
      Customer(
        id: a.id,
        name: 'AA A',
        createdAt: a.createdAt,
        updatedAt: a.updatedAt,
      ),
    );
    expect(updatedA.name, 'AA A');
  });

  test('update rejects missing customer', () async {
    final ghost = Customer(
      id: 'missing',
      name: 'Ghost',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    expect(() => customers.update(ghost), throwsA(isA<NotFoundException>()));
  });

  test('delete rejects missing customer', () {
    expect(
      () => customers.delete('missing'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('name can be reused after soft delete', () async {
    final c = await customers.create(name: 'Rosa');
    await customers.delete(c.id);

    final reused = await customers.create(name: 'Rosa');
    expect(reused.id, isNot(c.id));

    final all = await customers.getAll();
    expect(all, hasLength(1));
  });

  test('search is case-insensitive and trims the query', () async {
    await customers.create(name: 'Juan Dela Cruz');
    await customers.create(name: 'Maria Santos');

    expect(await customers.search('  JUAN  '), hasLength(1));
    expect(await customers.search('santos'), hasLength(1));
    expect(await customers.search('zzz'), isEmpty);
    expect(await customers.search('  '), hasLength(2));
  });

  test('count excludes soft-deleted customers', () async {
    final a = await customers.create(name: 'One');
    final b = await customers.create(name: 'Two');

    expect(await customers.count(), 2);
    await customers.delete(a.id);
    expect(await customers.count(), 1);
    expect((await customers.getAll()).single.id, b.id);
  });

  test('getById returns null for soft-deleted row', () async {
    final a = await customers.create(name: 'Hidden');
    await customers.delete(a.id);

    expect(await customers.getById(a.id), isNull);

    final row = await (db.select(
      db.customers,
    )..where((t) => t.id.equals(a.id))).getSingleOrNull();
    expect(row, isNotNull);
    expect(row!.deletedAt, isNotNull);

    final edited =
        await (db.update(db.customers)..where((t) => t.id.equals(a.id))).write(
          CustomersCompanion(deletedAt: Value(null)),
        );
    expect(edited, 1);
    expect((await customers.getById(a.id))?.name, 'Hidden');
  });

  test('trims names and empty notes/phone', () async {
    final c = await customers.create(
      name: '  Trimmed  ',
      phone: '  0917  ',
      notes: '   ',
    );

    expect(c.name, 'Trimmed');
    expect(c.phone, '0917');
    expect(c.notes, isNull);

    final debt = await debts.create(
      customerId: c.id,
      transactionDate: DateTime(2026, 1, 1),
      items: [
        DebtItemInput(
          productName: 'X',
          quantity: 1,
          price: Money.fromPesos(10),
        ),
      ],
    );
    expect(debt.customerName, 'Trimmed');
  });
}
