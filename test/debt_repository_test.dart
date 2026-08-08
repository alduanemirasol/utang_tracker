import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/payments/data/repositories/payment_repository_impl.dart';

void main() {
  late AppDatabase db;
  late CustomerRepositoryImpl customers;
  late DebtRepositoryImpl debts;
  late PaymentRepositoryImpl payments;

  setUp(() {
    db = AppDatabase.forTesting();
    customers = CustomerRepositoryImpl(db);
    debts = DebtRepositoryImpl(db);
    payments = PaymentRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> createCustomer(String name) async {
    return (await customers.create(name: name)).id;
  }

  DebtItemInput item({
    String productName = 'Bigas',
    double quantity = 1,
    String unit = 'bag',
    int pricePesos = 50,
  }) {
    return DebtItemInput(
      productName: productName,
      quantity: quantity,
      unit: unit,
      price: Money.fromCentavos(pricePesos * 100),
    );
  }

  Future<Debt> createWith(List<DebtItemInput> items, {String? customerId}) {
    return debts.create(
      customerId: customerId ?? 'missing',
      transactionDate: DateTime(2026, 1, 1),
      items: items,
    );
  }

  test('create validates items', () async {
    final customerId = await createCustomer('Validation');

    expect(
      () => createWith([], customerId: customerId),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createWith([item(productName: '   ')], customerId: customerId),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createWith([item(quantity: 0)], customerId: customerId),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createWith([item(unit: '')], customerId: customerId),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createWith([item(unit: 'a' * 25)], customerId: customerId),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createWith([item(pricePesos: 0)], customerId: customerId),
      throwsA(isA<ValidationException>()),
    );
  });

  test('create rejects missing customer', () {
    expect(() => createWith([item()]), throwsA(isA<NotFoundException>()));
  });

  test('update rejects missing or paid debt', () async {
    final customerId = await createCustomer('Ana');
    final debt = await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 1),
      items: [item(pricePesos: 100)],
    );
    await payments.recordPayment(
      debtId: debt.id,
      amount: Money.fromPesos(100),
      paymentDate: DateTime(2026, 1, 2),
      paymentMethod: 'Cash',
    );

    expect(
      () => debts.update(
        id: 'nope',
        transactionDate: DateTime(2026, 1, 1),
        items: [item()],
      ),
      throwsA(isA<NotFoundException>()),
    );
    expect(
      () => debts.update(
        id: debt.id,
        transactionDate: DateTime(2026, 1, 1),
        items: [item()],
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test('update replaces debt items atomically', () async {
    final customerId = await createCustomer('Pedro');
    final debt = await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 1),
      items: [item(productName: 'Old item')],
    );

    final updated = await debts.update(
      id: debt.id,
      transactionDate: DateTime(2026, 1, 3),
      items: [item(productName: 'New item', pricePesos: 75)],
    );

    expect(updated.totalAmount.centavos, 7500);
    final detail = await debts.getById(debt.id);
    expect(detail!.items, hasLength(1));
    expect(detail.items.single.productName, 'New item');

    final oldRows = await (db.select(
      db.debtItems,
    )..where((t) => t.debtId.equals(debt.id))).get();
    expect(oldRows, hasLength(2));
    expect(
      oldRows.every((r) => r.deletedAt != null || r.productName == 'New item'),
      isTrue,
    );
  });

  test('getAll filters by status', () async {
    final customerId = await createCustomer('Status');
    final unpaid = await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 1),
      items: [item(pricePesos: 30)],
    );
    final partial = await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 2),
      items: [item(pricePesos: 40)],
    );
    await payments.recordPayment(
      debtId: partial.id,
      amount: Money.fromPesos(10),
      paymentDate: DateTime(2026, 1, 3),
      paymentMethod: 'Cash',
    );
    final paid = await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 4),
      items: [item(pricePesos: 50)],
    );
    await payments.recordPayment(
      debtId: paid.id,
      amount: Money.fromPesos(50),
      paymentDate: DateTime(2026, 1, 5),
      paymentMethod: 'Cash',
    );

    expect(
      (await debts.getAll(status: DebtStatus.unpaid)).single.id,
      unpaid.id,
    );
    expect(
      (await debts.getAll(status: DebtStatus.partial)).single.id,
      partial.id,
    );
    expect((await debts.getAll(status: DebtStatus.paid)).single.id, paid.id);
    expect(await debts.getAll(), hasLength(3));
  });

  test('soft-deleted debt rows disappear from lists', () async {
    final customerId = await createCustomer('Rosa');
    final debt = await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 1),
      items: [item()],
    );

    await (db.update(db.debts)..where((t) => t.id.equals(debt.id))).write(
      DebtsCompanion(deletedAt: Value(DateTime.now().toUtc())),
    );
    expect(await debts.getById(debt.id), isNull);
    expect(await debts.getAll(), isEmpty);
    expect(await debts.getByCustomer(customerId), isEmpty);
  });

  test('countActive and outstandingBalance exclude paid debts', () async {
    final customerId = await createCustomer('Count');
    final paid = await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 1),
      items: [item(pricePesos: 20)],
    );
    await payments.recordPayment(
      debtId: paid.id,
      amount: Money.fromPesos(20),
      paymentDate: DateTime(2026, 1, 2),
      paymentMethod: 'Cash',
    );
    await debts.create(
      customerId: customerId,
      transactionDate: DateTime(2026, 1, 3),
      items: [item(pricePesos: 25)],
    );

    expect(await debts.countActive(), 1);
    expect(await debts.outstandingBalanceCentavos(), 2500);

    await (db.update(db.debts)..where((t) => t.id.equals(paid.id))).write(
      DebtsCompanion(
        status: Value(DebtStatus.paid.value),
        balance: Value(9999),
      ),
    );
    expect(await debts.countActive(), 1);
    expect(await debts.outstandingBalanceCentavos(), 2500);
  });
}
