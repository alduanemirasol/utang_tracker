import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/features/payments/domain/entities/payment.dart';
import 'package:utang_tracker/features/payments/domain/repositories/payment_repository.dart';
import 'package:utang_tracker/features/payments/presentation/pages/payments_list_page.dart';

void main() {
  testWidgets('payment time appears below amount and beside date', (
    tester,
  ) async {
    final paymentDate = DateTime(2026, 7, 15, 14, 5);
    final payment = Payment(
      id: 'payment-id',
      debtId: 'debt-id',
      amount: Money.fromPesos(125),
      paymentDate: paymentDate,
      paymentMethod: 'Cash',
      createdAt: paymentDate,
      customerName: 'Maria Santos',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(
            _FakePaymentRepository([payment]),
          ),
        ],
        child: const MaterialApp(home: PaymentsListPage()),
      ),
    );
    await tester.pumpAndSettle();

    final dateAndMethod = find.text(
      '${DateFormatters.formatDate(paymentDate)} · Cash',
    );
    final time = find.text(DateFormatters.formatTime(paymentDate));
    final amount = find.text(payment.amount.format());

    expect(dateAndMethod, findsOneWidget);
    expect(time, findsOneWidget);
    expect(amount, findsOneWidget);
    expect(
      tester.getTopLeft(time).dy,
      greaterThan(tester.getTopLeft(amount).dy),
    );
    expect(
      tester.getTopLeft(time).dy,
      closeTo(tester.getTopLeft(dateAndMethod).dy, 2),
    );
    expect(
      tester.getTopRight(time).dx,
      closeTo(tester.getTopRight(amount).dx, 1),
    );
  });
}

class _FakePaymentRepository implements PaymentRepository {
  const _FakePaymentRepository(this.payments);

  final List<Payment> payments;

  @override
  Future<List<Payment>> getAll() async => payments;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
