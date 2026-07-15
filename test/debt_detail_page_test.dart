import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';
import 'package:utang_tracker/features/debts/presentation/pages/debt_detail_page.dart';

void main() {
  testWidgets('items card shows aligned subtotals and a separated total', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final database = AppDatabase.forTesting();
    addTearDown(database.close);

    final customers = CustomerRepositoryImpl(database);
    final debts = DebtRepositoryImpl(database);
    final customer = await customers.create(name: 'Maria Santos');
    final debt = await debts.create(
      customerId: customer.id,
      transactionDate: DateTime(2026, 7, 15, 14, 5),
      items: [
        DebtItemInput(
          productName: 'Softdrinks',
          quantity: 2,
          unit: 'pcs',
          price: Money.fromPesos(50),
        ),
        DebtItemInput(
          productName: 'Premium long-grain rice refill',
          quantity: 0.5,
          unit: DebtItemUnits.kilogram,
          price: Money.fromPesos(80.25),
        ),
      ],
    );
    final detail = await debts.getById(debt.id);
    final softdrinks = detail!.items.singleWhere(
      (item) => item.productName == 'Softdrinks',
    );
    final rice = detail.items.singleWhere(
      (item) => item.productName == 'Premium long-grain rice refill',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(home: DebtDetailPage(debtId: debt.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(DateFormatters.formatDateTime(debt.transactionDate)),
      findsOneWidget,
    );
    expect(find.byKey(const Key('debt-items-card')), findsOneWidget);
    expect(find.text('Softdrinks'), findsOneWidget);
    expect(find.text('2 pcs'), findsOneWidget);
    expect(find.text('Premium long-grain rice refill'), findsOneWidget);
    expect(find.text('0.5 kg'), findsOneWidget);
    expect(find.byKey(const Key('debt-items-total-row')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('debt-items-total-row')),
        matching: find.text('Total'),
      ),
      findsOneWidget,
    );

    final softdrinksAmount = find.byKey(
      ValueKey('debt-item-subtotal-${softdrinks.id}'),
    );
    final riceAmount = find.byKey(ValueKey('debt-item-subtotal-${rice.id}'));
    final totalAmount = find.byKey(const Key('debt-items-total-amount'));
    final softdrinksNameFinder = find.byKey(
      ValueKey('debt-item-name-${softdrinks.id}'),
    );
    final softdrinksMetaFinder = find.byKey(
      ValueKey('debt-item-meta-${softdrinks.id}'),
    );
    final softdrinksName = tester.widget<Text>(softdrinksNameFinder);
    final softdrinksMeta = tester.widget<Text>(softdrinksMetaFinder);
    final textTheme = Theme.of(tester.element(softdrinksNameFinder)).textTheme;
    final softdrinksSubtotal = tester.widget<MoneyText>(softdrinksAmount);
    final itemsTotal = tester.widget<MoneyText>(totalAmount);

    expect(softdrinksMeta.style?.color, AppColors.textSecondary);
    expect(softdrinksName.style?.fontSize, textTheme.bodyMedium!.fontSize);
    expect(softdrinksMeta.style?.fontSize, textTheme.bodySmall!.fontSize);
    expect(softdrinksSubtotal.style?.fontSize, textTheme.bodyLarge!.fontSize);
    expect(itemsTotal.style, isNull);
    expect(find.text(softdrinks.price.format()), findsOneWidget);
    expect(find.text(rice.price.format()), findsOneWidget);
    expect(
      find.descendant(
        of: totalAmount,
        matching: find.text(debt.totalAmount.format()),
      ),
      findsOneWidget,
    );

    final rightEdges = [
      tester.getTopRight(softdrinksAmount).dx,
      tester.getTopRight(riceAmount).dx,
      tester.getTopRight(totalAmount).dx,
    ];
    for (final edge in rightEdges.skip(1)) {
      expect(edge, closeTo(rightEdges.first, 0.01));
    }
    expect(tester.takeException(), isNull);
  });
}
