import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/app.dart';

void main() {
  testWidgets('App renders placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(const UtangTrackerApp());
    expect(find.text('Utang Tracker'), findsNothing);
  });
}
