import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/features/help/presentation/pages/help_page.dart';

void main() {
  testWidgets('help page shows the manual guide', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpPage()));

    expect(find.text('Help'), findsOneWidget);
    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text('TIPS'), findsOneWidget);
    expect(
      find.text(
        'Record a utang: tap + New utang, pick the customer, add items, then Save.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Back up regularly: Settings > Backup & Restore.'),
      findsOneWidget,
    );
  });
}
