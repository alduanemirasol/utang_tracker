import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';
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
      (widget) => widget is AppTextField && widget.label == 'Price',
    );
    await tester.ensureVisible(priceField);
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
}
