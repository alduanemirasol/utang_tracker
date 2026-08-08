import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';
import 'package:utang_tracker/features/payments/domain/repositories/payment_repository.dart';
import 'package:utang_tracker/features/payments/domain/usecases/payment_usecases.dart';
import 'package:utang_tracker/features/payments/presentation/providers/payment_providers.dart';

class _FakePaymentRepository implements PaymentRepository {
  _FakePaymentRepository(this.payments);

  final List<Payment> payments;

  @override
  Future<List<Payment>> getAll() async => payments;

  @override
  Future<List<Payment>> getByDebt(String debtId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Payment>> getByCustomer(String customerId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Payment>> getRecent({int limit = 5}) async {
    throw UnimplementedError();
  }

  @override
  Future<Money> collectedBetween({
    required DateTime start,
    required DateTime end,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Payment> recordPayment({
    required String debtId,
    required Money amount,
    required DateTime paymentDate,
    required String paymentMethod,
    String? notes,
  }) {
    throw UnimplementedError();
  }
}

Payment _payment({
  required String id,
  required DateTime paymentDateUtc,
  String? customerName,
  String paymentMethod = 'Cash',
}) {
  return Payment(
    id: id,
    debtId: 'debt-$id',
    amount: Money.fromPesos(50),
    paymentDate: paymentDateUtc,
    paymentMethod: paymentMethod,
    createdAt: paymentDateUtc,
    customerName: customerName,
  );
}

/// Builds a UTC instant that corresponds to `hour:minute` on `localDay` in
/// the test machine's local timezone.
DateTime _utcInstantOf(
  DateTime localDay, {
  required int hour,
  required int minute,
}) {
  return DateTime(
    localDay.year,
    localDay.month,
    localDay.day,
    hour,
    minute,
  ).toUtc();
}

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  test(
    'payments at local edges of a day match a same-day date filter',
    () async {
      final container = ProviderContainer(
        overrides: [
          getPaymentsProvider.overrideWith(
            (ref) => GetPayments(
              _FakePaymentRepository([
                _payment(
                  id: 'early',
                  paymentDateUtc: _utcInstantOf(today, hour: 0, minute: 30),
                ),
                _payment(
                  id: 'late',
                  paymentDateUtc: _utcInstantOf(today, hour: 23, minute: 30),
                ),
                _payment(
                  id: 'yesterday',
                  paymentDateUtc: _utcInstantOf(
                    today.subtract(const Duration(days: 1)),
                    hour: 23,
                    minute: 59,
                  ),
                ),
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(paymentFiltersProvider.notifier)
          .setDateRange(startDate: today, endDate: today);

      final result = await container.read(paymentsListProvider.future);
      expect(result.map((p) => p.id), ['early', 'late']);
    },
  );

  test(
    'date range spanning the UTC boundary includes local-day edges',
    () async {
      final tomorrow = today.add(const Duration(days: 1));
      final container = ProviderContainer(
        overrides: [
          getPaymentsProvider.overrideWith(
            (ref) => GetPayments(
              _FakePaymentRepository([
                _payment(
                  id: 'day2-midnight',
                  paymentDateUtc: _utcInstantOf(tomorrow, hour: 0, minute: 1),
                ),
                _payment(
                  id: 'outside',
                  paymentDateUtc: _utcInstantOf(
                    tomorrow.add(const Duration(days: 1)),
                    hour: 23,
                    minute: 30,
                  ),
                ),
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(paymentFiltersProvider.notifier)
          .setDateRange(startDate: today, endDate: tomorrow);

      final result = await container.read(paymentsListProvider.future);
      expect(result.map((p) => p.id), ['day2-midnight']);
    },
  );

  test('payment method filter narrows results', () async {
    final container = ProviderContainer(
      overrides: [
        getPaymentsProvider.overrideWith(
          (ref) => GetPayments(
            _FakePaymentRepository([
              _payment(id: 'cash', paymentDateUtc: today.toUtc()),
              _payment(
                id: 'gcash',
                paymentDateUtc: today.toUtc(),
                paymentMethod: 'GCash',
              ),
            ]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(paymentFiltersProvider.notifier).setPaymentMethod('GCash');

    final result = await container.read(paymentsListProvider.future);
    expect(result.map((p) => p.id), ['gcash']);
  });

  test('search query filters by customer name case-insensitively', () async {
    final container = ProviderContainer(
      overrides: [
        getPaymentsProvider.overrideWith(
          (ref) => GetPayments(
            _FakePaymentRepository([
              _payment(
                id: 'juan',
                paymentDateUtc: today.toUtc(),
                customerName: 'Juan Dela Cruz',
              ),
              _payment(
                id: 'maria',
                paymentDateUtc: today.toUtc(),
                customerName: 'Maria Santos',
              ),
            ]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(paymentFiltersProvider.notifier).setSearchQuery('JUAN');

    final result = await container.read(paymentsListProvider.future);
    expect(result.map((p) => p.id), ['juan']);
  });
}
