import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utang_tracker/app/coordination.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_reminder.dart';
import 'package:utang_tracker/features/notifications/domain/repositories/reminder_scheduler.dart';
import 'package:utang_tracker/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:utang_tracker/features/payments/presentation/providers/payment_providers.dart';

class _FakeReminderScheduler implements ReminderScheduler {
  int rescheduleCount = 0;
  int cancelCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> rescheduleAll(List<DebtReminder> reminders) async {
    rescheduleCount++;
  }

  @override
  Future<void> cancelAll() async {
    cancelCount++;
  }
}

class _RefHarness extends ConsumerWidget {
  const _RefHarness({required this.onRef});

  final void Function(WidgetRef ref) onRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onRef(ref);
    return const SizedBox();
  }
}

void main() {
  late AppDatabase db;
  late CustomerRepositoryImpl customers;
  late DebtRepositoryImpl debts;
  late PaymentRepositoryImpl payments;
  late _FakeReminderScheduler fakeScheduler;
  late WidgetRef harnessRef;
  var customerRepoBuilds = 0;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting();
    customers = CustomerRepositoryImpl(db);
    debts = DebtRepositoryImpl(db);
    payments = PaymentRepositoryImpl(db);
    fakeScheduler = _FakeReminderScheduler();
    customerRepoBuilds = 0;
    addTearDown(() => db.close());
  });

  Future<void> pumpHarness(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          customerRepositoryProvider.overrideWith((ref) {
            customerRepoBuilds++;
            return CustomerRepositoryImpl(ref.watch(databaseProvider));
          }),
          debtRepositoryProvider.overrideWith(
            (ref) => DebtRepositoryImpl(ref.watch(databaseProvider)),
          ),
          paymentRepositoryProvider.overrideWith(
            (ref) => PaymentRepositoryImpl(ref.watch(databaseProvider)),
          ),
          reminderSchedulerProvider.overrideWithValue(fakeScheduler),
        ],
        child: _RefHarness(onRef: (ref) => harnessRef = ref),
      ),
    );
    await tester.pump();
  }

  testWidgets('invalidates list and dashboard providers after writes', (
    tester,
  ) async {
    await pumpHarness(tester);

    expect(await harnessRef.read(customersListProvider.future), isEmpty);

    final customer = await customers.create(name: 'New customer');
    final debt = await debts.create(
      customerId: customer.id,
      transactionDate: DateTime.now(),
      items: [
        DebtItemInput(
          productName: 'Rice',
          quantity: 1,
          price: Money.fromPesos(50),
        ),
      ],
    );
    await payments.recordPayment(
      debtId: debt.id,
      amount: Money.fromPesos(20),
      paymentDate: DateTime.now(),
      paymentMethod: 'Cash',
    );

    invalidateBusinessData(
      harnessRef,
      customerId: customer.id,
      debtId: debt.id,
    );
    await tester.pump();

    expect(await harnessRef.read(customersListProvider.future), hasLength(1));
    expect(await harnessRef.read(debtsListProvider.future), hasLength(1));
    expect(await harnessRef.read(paymentsListProvider.future), hasLength(1));
    final options = await harnessRef.read(paymentFilterOptionsProvider.future);
    expect(options.hasPayments, isTrue);

    final dashboard = await harnessRef.read(dashboardSummaryProvider.future);
    expect(dashboard.collectedToday.centavos, 2000);
    expect(dashboard.activeDebtsCount, 1);

    await tester.pumpAndSettle();
    expect(fakeScheduler.rescheduleCount, greaterThan(0));
  });

  testWidgets('refreshes a specific customer detail after invalidation', (
    tester,
  ) async {
    await pumpHarness(tester);

    final customer = await customers.create(name: 'Detail customer');
    await debts.create(
      customerId: customer.id,
      transactionDate: DateTime(2026, 7, 19),
      items: [
        DebtItemInput(
          productName: 'Rice',
          quantity: 1,
          price: Money.fromPesos(30),
        ),
      ],
    );

    final detailBefore = await harnessRef.read(
      customerDetailProvider(customer.id).future,
    );
    expect(detailBefore!.debts, hasLength(1));

    await debts.create(
      customerId: customer.id,
      transactionDate: DateTime(2026, 7, 20),
      items: [
        DebtItemInput(
          productName: 'Noodles',
          quantity: 1,
          price: Money.fromPesos(10),
        ),
      ],
    );

    invalidateBusinessData(harnessRef, customerId: customer.id);
    await tester.pump();

    final detailAfter = await harnessRef.read(
      customerDetailProvider(customer.id).future,
    );
    expect(detailAfter!.debts, hasLength(2));
  });

  testWidgets('refreshAfterDatabaseRestore rebuilds repositories', (
    tester,
  ) async {
    await pumpHarness(tester);

    await harnessRef.read(customersListProvider.future);
    final beforeBuilds = customerRepoBuilds;
    expect(beforeBuilds, 1);

    refreshAfterDatabaseRestore(harnessRef);
    await tester.pump();

    final list = await harnessRef.read(customersListProvider.future);
    expect(list, isEmpty);
    expect(customerRepoBuilds, beforeBuilds + 1);

    await tester.pumpAndSettle();
    expect(fakeScheduler.rescheduleCount, greaterThan(0));
  });
}
