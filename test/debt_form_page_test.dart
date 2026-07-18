import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
import 'package:utang_tracker/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';
import 'package:utang_tracker/features/debts/presentation/pages/debt_form_page.dart';

void main() {
  testWidgets('each debt item card shows a live subtotal row', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const DebtFormPage()),
      ),
    );

    final transactionDate = find.text('Today');
    expect(transactionDate, findsOneWidget);
    expect(
      tester.widget<Text>(transactionDate).style?.fontWeight,
      FontWeight.w500,
    );
    expect(
      tester.widget<Text>(find.text('Select customer')).style?.fontWeight,
      FontWeight.w500,
    );

    final unitValue = find.text(DebtItemUnits.displayName(DebtItemUnits.piece));
    expect(tester.widget<Text>(unitValue).style?.fontWeight, FontWeight.w500);

    final firstSubtotal = find.byKey(
      const ValueKey('debt-form-item-subtotal-amount-0'),
    );
    expect(find.text('Subtotal'), findsOneWidget);
    expect(
      find.descendant(
        of: firstSubtotal,
        matching: find.text(Money.zero().format()),
      ),
      findsOneWidget,
    );

    final priceField = find.byWidgetPredicate(
      (widget) => widget is AppTextField && widget.label == 'Price *',
    );
    await tester.ensureVisible(priceField);
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: priceField, matching: find.byType(TextField)),
          )
          .style
          ?.fontWeight,
      FontWeight.w500,
    );
    await tester.enterText(
      find.descendant(of: priceField, matching: find.byType(TextField)),
      '75.50',
    );
    await tester.pump();

    expect(
      find.descendant(
        of: firstSubtotal,
        matching: find.text(Money.fromPesos(75.50).format()),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();
    expect(firstSubtotal, findsOneWidget);

    await tester.ensureVisible(find.text('Add item'));
    await tester.tap(find.text('Add item'));
    await tester.pump();

    expect(find.text('Subtotal'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('debt-form-item-subtotal-amount-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom unit dialog stays compact', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const DebtFormPage()),
      ),
    );

    final unit = find.text(DebtItemUnits.displayName(DebtItemUnits.piece));
    await tester.ensureVisible(unit);
    await tester.tap(unit);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Custom unit'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const Key('app-modal-bottom-sheet')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('Custom unit'));
    await tester.pumpAndSettle();

    final dialog = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byWidgetPredicate(
        (widget) => widget is Material && widget.type == MaterialType.card,
      ),
    );
    final dialogSize = tester.getSize(dialog);
    expect(dialogSize.width, lessThanOrEqualTo(360));
    expect(dialogSize.height, lessThanOrEqualTo(260));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adding an item collapses all previous item forms', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const DebtFormPage()),
      ),
    );

    final addItem = find.text('Add item');
    await tester.ensureVisible(addItem);
    await tester.tap(addItem);
    await tester.pump();

    final collapsedSummary =
        'No product yet · 1 '
        '${DebtItemUnits.displayName(DebtItemUnits.piece)}';
    expect(find.text(collapsedSummary), findsOneWidget);
    expect(find.text('Product *'), findsOneWidget);

    await tester.tap(addItem);
    await tester.pump();

    expect(find.text(collapsedSummary), findsNWidgets(2));
    expect(find.text('Product *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('required debt fields show and clear inline errors', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const DebtFormPage()),
      ),
    );

    expect(find.text('Product *'), findsOneWidget);
    expect(find.text('Qty *'), findsOneWidget);
    expect(find.text('Price *'), findsOneWidget);

    final addItem = find.text('Add item');
    await tester.ensureVisible(addItem);
    await tester.tap(addItem);
    await tester.pump();
    expect(find.text('Product *'), findsOneWidget);
    final collapsedSummary =
        'No product yet · 1 '
        '${DebtItemUnits.displayName(DebtItemUnits.piece)}';
    expect(find.text(collapsedSummary), findsOneWidget);

    final save = find.text('Save');
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(save, 500, scrollable: scrollable);
    await tester.tap(save);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Select customer'),
      -500,
      scrollable: scrollable,
    );
    expect(find.text('Select a customer.'), findsOneWidget);
    expect(find.text(collapsedSummary), findsNothing);

    final customerDecorator = find.ancestor(
      of: find.text('Select customer'),
      matching: find.byType(InputDecorator),
    );
    expect(
      tester.widget<InputDecorator>(customerDecorator).decoration.errorText,
      'Select a customer.',
    );

    final productFields = find.byWidgetPredicate(
      (widget) => widget is AppTextField && widget.label == 'Product *',
    );
    final firstProductInput = find
        .descendant(of: productFields, matching: find.byType(TextField))
        .first;
    expect(
      tester.widget<TextField>(firstProductInput).decoration?.errorText,
      'Product is required.',
    );

    await tester.enterText(firstProductInput, 'Rice');
    await tester.pump();
    expect(
      tester.widget<TextField>(firstProductInput).decoration?.errorText,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer picker check follows the selected customer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final database = AppDatabase.forTesting();
    addTearDown(database.close);
    final customers = CustomerRepositoryImpl(database);
    final maria = await customers.create(name: 'Maria Santos');
    await customers.create(name: 'Juan Cruz');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: DebtFormPage(initialCustomerId: maria.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Maria Santos'));
    await tester.pumpAndSettle();

    Finder customerTile(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(ListTile));
    Finder checkIn(Finder tile) =>
        find.descendant(of: tile, matching: find.byIcon(Icons.check));

    final mariaTile = customerTile('Maria Santos');
    final juanTile = customerTile('Juan Cruz');
    final mariaCheck = checkIn(mariaTile);

    expect(mariaTile, findsOneWidget);
    expect(juanTile, findsOneWidget);
    expect(mariaCheck, findsOneWidget);
    expect(checkIn(juanTile), findsNothing);
    expect(tester.widget<Icon>(mariaCheck).color, AppColors.primaryDark);

    await tester.tap(juanTile);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Juan Cruz'));
    await tester.pumpAndSettle();

    final reopenedMariaTile = customerTile('Maria Santos');
    final reopenedJuanTile = customerTile('Juan Cruz');
    final juanCheck = checkIn(reopenedJuanTile);

    expect(checkIn(reopenedMariaTile), findsNothing);
    expect(juanCheck, findsOneWidget);
    expect(tester.widget<Icon>(juanCheck).color, AppColors.primaryDark);
    expect(tester.takeException(), isNull);
  });
}
