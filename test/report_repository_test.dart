import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:utang_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';

void main() {
  late AppDatabase db;
  late CustomerRepositoryImpl customers;
  late DebtRepositoryImpl debts;
  late PaymentRepositoryImpl payments;
  late ReportRepositoryImpl reports;

  setUp(() {
    db = AppDatabase.forTesting();
    customers = CustomerRepositoryImpl(db);
    debts = DebtRepositoryImpl(db);
    payments = PaymentRepositoryImpl(db);
    reports = ReportRepositoryImpl(debts: debts, payments: payments);
  });

  tearDown(() async {
    await db.close();
  });

  test('groups collections by customer and sums overdue by bucket', () async {
    final now = DateTime.now();
    final ana = await customers.create(name: 'Ana');
    final bea = await customers.create(name: 'Bea');
    final anaDebt = await debts.create(
      customerId: ana.id,
      transactionDate: now,
      dueDate: now.subtract(const Duration(days: 5)),
      items: [
        DebtItemInput(
          productName: 'Bigas',
          quantity: 1,
          price: Money.fromPesos(100),
        ),
      ],
    );
    final beaDebt = await debts.create(
      customerId: bea.id,
      transactionDate: now,
      dueDate: now,
      items: [
        DebtItemInput(
          productName: 'Asin',
          quantity: 1,
          price: Money.fromPesos(50),
        ),
      ],
    );

    await payments.recordPayment(
      debtId: anaDebt.id,
      amount: Money.fromPesos(60),
      paymentDate: now,
      paymentMethod: 'Cash',
    );
    await payments.recordPayment(
      debtId: beaDebt.id,
      amount: Money.fromPesos(50),
      paymentDate: now,
      paymentMethod: 'GCash',
    );

    final report = await reports.getCollectionReport(
      period: CollectionPeriod.today,
      now: now,
    );

    expect(report.collectedTotal.centavos, 11000);
    expect(report.paymentCount, 2);
    expect(report.perCustomer.length, 2);

    final anaTotal = report.perCustomer.firstWhere(
      (item) => item.customerName == 'Ana',
    );
    expect(anaTotal.total.centavos, 6000);
    expect(anaTotal.paymentCount, 1);

    final beaTotal = report.perCustomer.firstWhere(
      (item) => item.customerName == 'Bea',
    );
    expect(beaTotal.total.centavos, 5000);
    expect(beaTotal.paymentCount, 1);

    expect(report.overdueBuckets[0].debtCount, 1);
    expect(report.overdueBuckets[0].total.centavos, 4000);
    expect(report.overdueBuckets[1].debtCount, 0);
    expect(report.overdueBuckets[2].debtCount, 0);
  });

  test('excludes payments outside the selected day', () async {
    final now = DateTime.now();
    final customer = await customers.create(name: 'Cora');
    final debt = await debts.create(
      customerId: customer.id,
      transactionDate: now,
      items: [
        DebtItemInput(
          productName: 'Sardinas',
          quantity: 1,
          price: Money.fromPesos(100),
        ),
      ],
    );

    await payments.recordPayment(
      debtId: debt.id,
      amount: Money.fromPesos(10),
      paymentDate: now,
      paymentMethod: 'Cash',
    );
    await payments.recordPayment(
      debtId: debt.id,
      amount: Money.fromPesos(20),
      paymentDate: now.subtract(const Duration(days: 1)),
      paymentMethod: 'Cash',
    );

    final report = await reports.getCollectionReport(
      period: CollectionPeriod.today,
      now: now,
    );

    expect(report.paymentCount, 1);
    expect(report.collectedTotal.centavos, 1000);
    expect(report.perCustomer.single.customerName, 'Cora');
  });
}