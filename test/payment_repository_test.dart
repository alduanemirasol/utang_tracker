import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';
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

  test('create debt and record partial then full payment', () async {
    final customer = await customers.create(name: 'Maria');
    final debt = await debts.create(
      customerId: customer.id,
      transactionDate: DateTime.now(),
      items: [
        DebtItemInput(
          productName: 'Bigas',
          quantity: 2,
          unit: DebtItemUnits.kilogram,
          price: Money.fromPesos(50),
        ),
        DebtItemInput(
          productName: 'Noodles',
          quantity: 3,
          price: Money.fromPesos(10),
        ),
      ],
    );

    // Quantity is descriptive; custom item prices are summed directly.
    expect(debt.totalAmount.centavos, 6000);
    expect(debt.paidAmount.isZero, isTrue);
    expect(debt.balance.centavos, 6000);
    expect(debt.status, DebtStatus.unpaid);

    final createdDetail = await debts.getById(debt.id);
    expect(createdDetail!.items[0].unit, DebtItemUnits.kilogram);
    expect(createdDetail.items[1].unit, DebtItemUnits.piece);

    await payments.recordPayment(
      debtId: debt.id,
      amount: Money.fromPesos(20),
      paymentDate: DateTime.now(),
      paymentMethod: 'Cash',
    );

    final partial = await debts.getById(debt.id);
    expect(partial!.debt.status, DebtStatus.partial);
    expect(partial.debt.paidAmount.centavos, 2000);
    expect(partial.debt.balance.centavos, 4000);

    await payments.recordPayment(
      debtId: debt.id,
      amount: Money.fromPesos(40),
      paymentDate: DateTime.now(),
      paymentMethod: 'GCash',
    );

    final paid = await debts.getById(debt.id);
    expect(paid!.debt.status, DebtStatus.paid);
    expect(paid.debt.balance.isZero, isTrue);

    expect(
      () => payments.recordPayment(
        debtId: debt.id,
        amount: Money.fromPesos(1),
        paymentDate: DateTime.now(),
        paymentMethod: 'Cash',
      ),
      throwsA(isA<ConflictException>()),
    );
  });

  test('rejects overpayment', () async {
    final customer = await customers.create(name: 'Juan');
    final debt = await debts.create(
      customerId: customer.id,
      transactionDate: DateTime.now(),
      items: [
        DebtItemInput(
          productName: 'Soda',
          quantity: 1,
          price: Money.fromPesos(20),
        ),
      ],
    );

    expect(
      () => payments.recordPayment(
        debtId: debt.id,
        amount: Money.fromPesos(50),
        paymentDate: DateTime.now(),
        paymentMethod: 'Cash',
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('cannot delete customer with debts', () async {
    final customer = await customers.create(name: 'Ana');
    await debts.create(
      customerId: customer.id,
      transactionDate: DateTime.now(),
      items: [
        DebtItemInput(
          productName: 'Item',
          quantity: 1,
          price: Money.fromPesos(10),
        ),
      ],
    );

    expect(
      () => customers.delete(customer.id),
      throwsA(isA<ConflictException>()),
    );
  });

  test('soft deletes customer and keeps row hidden from lists', () async {
    final customer = await customers.create(name: 'Pedro');
    await customers.delete(customer.id);

    final listed = await customers.getAll();
    expect(listed.where((c) => c.id == customer.id), isEmpty);
    expect(await customers.getById(customer.id), isNull);

    // Row still exists in the database with deleted_at set.
    final row = await (db.select(
      db.customers,
    )..where((t) => t.id.equals(customer.id))).getSingleOrNull();
    expect(row, isNotNull);
    expect(row!.deletedAt, isNotNull);
  });
}
