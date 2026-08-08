import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/domain/money.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/domain/repositories/debt_repository.dart';
import 'package:utang_tracker/features/debts/domain/usecases/debt_usecases.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';
import 'package:utang_tracker/features/payments/presentation/pages/record_payment_page.dart';

class _FakeDebtRepository implements DebtRepository {
  _FakeDebtRepository(this._details);

  final Map<String, DebtDetail> _details;

  @override
  Future<DebtDetail?> getById(String id) async => _details[id];

  @override
  Future<List<Debt>> getAll({DebtStatus? status}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Debt>> getByCustomer(String customerId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Debt>> getRecent({int limit = 5, DebtStatus? status}) async {
    throw UnimplementedError();
  }

  @override
  Future<Debt> create({
    required String customerId,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
    required List<DebtItemInput> items,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Debt> update({
    required String id,
    required DateTime transactionDate,
    DateTime? dueDate,
    String? notes,
    required List<DebtItemInput> items,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> countActive() async => throw UnimplementedError();

  @override
  Future<int> outstandingBalanceCentavos() async => throw UnimplementedError();
}

Debt _makeDebt({required String id, required DebtStatus status}) {
  final balance = status == DebtStatus.paid
      ? Money.zero()
      : Money.fromPesos(100);
  return Debt(
    id: id,
    customerId: 'cust-1',
    totalAmount: Money.fromPesos(status == DebtStatus.paid ? 100 : 100),
    paidAmount: status == DebtStatus.paid ? Money.fromPesos(100) : Money.zero(),
    balance: balance,
    status: status,
    transactionDate: DateTime(2026, 1, 1),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    customerName: 'Juan Test',
  );
}

void main() {
  testWidgets('required payment fields show and clear inline errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const RecordPaymentPage(),
        ),
      ),
    );

    final confirmRow = find.byKey(const Key('confirm-payment-row'));
    final notesField = find.byWidgetPredicate(
      (widget) => widget is AppTextField && widget.label == 'Notes',
    );
    await tester.ensureVisible(confirmRow);
    await tester.pump();
    expect(
      tester.getTopLeft(confirmRow).dy - tester.getBottomLeft(notesField).dy,
      AppSpacing.lg,
    );

    final confirmCheckbox = find.byType(Checkbox);
    expect(confirmCheckbox, findsOneWidget);
    await tester.tap(confirmCheckbox);
    await tester.pump();

    final save = find.text('Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(find.text('Select utang'), findsAtLeastNWidgets(1));
    expect(find.text('Amount is required.'), findsOneWidget);

    final debtDecorator = find
        .ancestor(
          of: find.text('Select utang'),
          matching: find.byType(InputDecorator),
        )
        .first;
    expect(
      tester.widget<InputDecorator>(debtDecorator).decoration.errorText,
      'Select utang',
    );

    final amountField = find.byWidgetPredicate(
      (widget) => widget is AppTextField && widget.label == 'Amount *',
    );
    final amountInput = find.descendant(
      of: amountField,
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(amountInput).decoration?.errorText,
      'Amount is required.',
    );

    await tester.enterText(amountInput, '100');
    await tester.pump();
    expect(tester.widget<TextField>(amountInput).decoration?.errorText, isNull);
    expect(tester.takeException(), isNull);
    expect(find.text('Save ₱100.00'), findsOneWidget);
  });

  testWidgets('deleted initial debt clears selection instead of keeping it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getDebtDetailProvider.overrideWithValue(
            GetDebtDetail(_FakeDebtRepository(const {})),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const RecordPaymentPage(initialDebtId: 'deleted-debt'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select utang'), findsOneWidget);
    expect(find.text('Remaining balance: ₱100.00'), findsNothing);
  });

  testWidgets('paid initial debt clears selection', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = _FakeDebtRepository({
      'paid-debt': DebtDetail(
        debt: _makeDebt(id: 'paid-debt', status: DebtStatus.paid),
        items: const [],
      ),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          getDebtDetailProvider.overrideWithValue(GetDebtDetail(repo)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const RecordPaymentPage(initialDebtId: 'paid-debt'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select utang'), findsOneWidget);

    final confirmCheckbox = find.byType(Checkbox);
    await tester.tap(confirmCheckbox);
    await tester.pump();

    final save = find.text('Save');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();

    expect(find.text('Select utang'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}
