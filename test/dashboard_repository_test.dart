import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/recent_activity_item.dart';
import 'package:utang_tracker/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/payments/data/repositories/payment_repository_impl.dart';

void main() {
  late AppDatabase db;
  late CustomerRepositoryImpl customers;
  late DebtRepositoryImpl debts;
  late PaymentRepositoryImpl payments;
  late DashboardRepositoryImpl dashboard;
  late DateTime now;

  setUp(() {
    db = AppDatabase.forTesting();
    customers = CustomerRepositoryImpl(db);
    now = DateTime(2026, 7, 19, 12, 0, 0);
    debts = DebtRepositoryImpl(db, now: () => now);
    payments = PaymentRepositoryImpl(db, now: () => now);
    dashboard = DashboardRepositoryImpl(
      customers: customers,
      debts: debts,
      payments: payments,
      now: () => now,
    );
  });

  tearDown(() async {
    await db.close();
  });

  var helperCounter = 0;

  Future<String> createDebtWithPayment({
    required int amountPesos,
    DateTime? paymentDay,
  }) async {
    helperCounter++;
    final customer = await customers.create(
      name: 'Collector test $helperCounter',
    );
    final debt = await debts.create(
      customerId: customer.id,
      transactionDate: DateTime(2026, 7, 10),
      items: [
        DebtItemInput(
          productName: 'Item',
          quantity: 1,
          price: Money.fromCentavos((amountPesos + 10) * 100),
        ),
      ],
    );
    await payments.recordPayment(
      debtId: debt.id,
      amount: Money.fromCentavos(amountPesos * 100),
      paymentDate: paymentDay ?? DateTime(2026, 7, 19),
      paymentMethod: 'Cash',
    );
    return debt.id;
  }

  test('collectedToday includes both ends of the local day', () async {
    now = DateTime(2026, 7, 19, 0, 0, 0);
    await createDebtWithPayment(amountPesos: 30);

    now = DateTime(2026, 7, 19, 23, 59, 59, 999);
    await createDebtWithPayment(amountPesos: 20);

    now = DateTime(2026, 7, 20, 0, 0, 0);
    await createDebtWithPayment(
      amountPesos: 999,
      paymentDay: DateTime(2026, 7, 20),
    );

    now = DateTime(2026, 7, 19, 12, 0, 0);

    final data = await dashboard.getDashboardData();
    expect(data.collectedToday.centavos, 5000);
  });

  test('collectedToday excludes previous local day', () async {
    now = DateTime(2026, 7, 18, 23, 59, 59, 999);
    await createDebtWithPayment(
      amountPesos: 40,
      paymentDay: DateTime(2026, 7, 18),
    );

    now = DateTime(2026, 7, 19, 12, 0, 0);
    final data = await dashboard.getDashboardData();
    expect(data.collectedToday.isZero, isTrue);
  });

  test('counts only active debts and customers', () async {
    final customerA = await customers.create(name: 'A');
    final customerB = await customers.create(name: 'B');

    await debts.create(
      customerId: customerA.id,
      transactionDate: DateTime(2026, 7, 1),
      items: [
        DebtItemInput(
          productName: 'X',
          quantity: 1,
          price: Money.fromPesos(40),
        ),
      ],
    );
    final paidDebt = await debts.create(
      customerId: customerA.id,
      transactionDate: DateTime(2026, 7, 2),
      items: [
        DebtItemInput(
          productName: 'Y',
          quantity: 1,
          price: Money.fromPesos(30),
        ),
      ],
    );
    await payments.recordPayment(
      debtId: paidDebt.id,
      amount: Money.fromPesos(30),
      paymentDate: DateTime(2026, 7, 19),
      paymentMethod: 'Cash',
    );
    final bDebt = await debts.create(
      customerId: customerB.id,
      transactionDate: DateTime(2026, 7, 3),
      items: [
        DebtItemInput(
          productName: 'Z',
          quantity: 1,
          price: Money.fromPesos(25),
        ),
      ],
    );
    await payments.recordPayment(
      debtId: bDebt.id,
      amount: Money.fromPesos(25),
      paymentDate: DateTime(2026, 7, 19),
      paymentMethod: 'Cash',
    );

    await customers.delete(customerB.id);

    final data = await dashboard.getDashboardData();
    expect(data.activeDebtsCount, 1);
    expect(data.totalCustomers, 1);
    expect(data.outstandingBalance.centavos, 4000);
  });

  test(
    'recent activity merges debts and payments, sorted desc, truncated',
    () async {
      final useCase = GetDashboardSummary(dashboard);

      final customerA = await customers.create(name: 'Anna');
      final customerB = await customers.create(name: 'Bob');

      for (var i = 0; i < 3; i++) {
        now = DateTime(2026, 7, 19, 5 + i, 0, 0);
        await debts.create(
          customerId: customerA.id,
          transactionDate: DateTime(2026, 7, 10),
          items: [
            DebtItemInput(
              productName: 'Debt $i',
              quantity: 1,
              price: Money.fromPesos(10),
            ),
          ],
        );
      }

      final paymentDebts = <String>[];
      for (var i = 0; i < 3; i++) {
        now = DateTime(2026, 7, 19, 8 + i, 0, 0);
        paymentDebts.add(
          (await debts.create(
            customerId: customerB.id,
            transactionDate: DateTime(2026, 7, 10),
            items: [
              DebtItemInput(
                productName: 'Item $i',
                quantity: 1,
                price: Money.fromPesos(100),
              ),
            ],
          )).id,
        );
      }

      for (var i = 0; i < 3; i++) {
        now = DateTime(2026, 7, 19, 11 + i, 0, 0);
        await payments.recordPayment(
          debtId: paymentDebts[i],
          amount: Money.fromPesos(5),
          paymentDate: DateTime(2026, 7, 19),
          paymentMethod: 'Cash',
        );
      }
      now = DateTime(2026, 7, 19, 12, 0, 0);

      final summary = await useCase();
      expect(summary.recentActivity, hasLength(AppConstants.recentItemsLimit));
      expect(summary.recentActivity.first.type, RecentActivityType.payment);
      expect(
        summary.recentActivity
            .take(3)
            .every(
              (e) =>
                  e.type == RecentActivityType.payment &&
                  e.customerName == 'Bob',
            ),
        isTrue,
      );
      expect(
        summary.recentActivity
            .skip(3)
            .every(
              (e) =>
                  e.type == RecentActivityType.debt && e.customerName == 'Bob',
            ),
        isTrue,
      );
      for (var i = 0; i < summary.recentActivity.length - 1; i++) {
        expect(
          summary.recentActivity[i].date.isBefore(
            summary.recentActivity[i + 1].date,
          ),
          isFalse,
        );
      }
    },
  );
}
