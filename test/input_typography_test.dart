import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/widgets/app_search_bar.dart';
import 'package:utang_tracker/core/widgets/app_text_field.dart';

void main() {
  testWidgets('editable and search text use the shared medium input weight', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Maria');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              AppTextField(
                key: const Key('customer-field'),
                controller: controller,
                label: 'Customer',
                hint: 'Customer name',
              ),
              AppSearchBar(
                key: const Key('customer-search'),
                initialValue: 'Maria',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    final fieldFinder = find.descendant(
      of: find.byKey(const Key('customer-field')),
      matching: find.byType(TextField),
    );
    final searchFinder = find.descendant(
      of: find.byKey(const Key('customer-search')),
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(fieldFinder);
    final search = tester.widget<TextField>(searchFinder);
    final label = tester.widget<Text>(find.text('Customer'));
    final textTheme = Theme.of(tester.element(fieldFinder)).textTheme;

    for (final input in [field, search]) {
      expect(input.style?.fontFamily, 'Poppins');
      expect(input.style?.fontSize, textTheme.bodyMedium?.fontSize);
      expect(input.style?.fontWeight, FontWeight.w500);
    }

    expect(label.style?.fontWeight, FontWeight.w600);
  });
}
