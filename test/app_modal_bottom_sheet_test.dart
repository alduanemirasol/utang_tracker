import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/widgets/app_modal_bottom_sheet.dart';

void main() {
  test('bottom sheet theme defines the shared modal treatment', () {
    final bottomSheetTheme = AppTheme.light().bottomSheetTheme;

    expect(bottomSheetTheme.backgroundColor, AppColors.surfaceCard);
    expect(bottomSheetTheme.modalBackgroundColor, AppColors.surfaceCard);
    expect(bottomSheetTheme.modalBarrierColor, AppColors.scrim);
    expect(bottomSheetTheme.modalElevation, 2);
    expect(bottomSheetTheme.showDragHandle, isTrue);
    expect(bottomSheetTheme.dragHandleColor, AppColors.textMuted);
    expect(bottomSheetTheme.dragHandleSize, const Size(40, 4));
    expect(bottomSheetTheme.clipBehavior, Clip.antiAlias);
    expect(
      bottomSheetTheme.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  });

  testWidgets('shared modal presents one draggable sheet at standard height', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showAppModalBottomSheet<void>(
                  context: context,
                  builder: (_) => const AppModalBottomSheet(
                    title: 'Select entry',
                    subtitle: 'Choose from the ledger.',
                    child: Center(child: Text('Sheet content')),
                  ),
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    final bottomSheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    final sheetShell = find.byKey(const Key('app-modal-bottom-sheet'));
    final availableHeight = MediaQuery.sizeOf(
      tester.element(sheetShell),
    ).height;

    expect(bottomSheet.enableDrag, isTrue);
    expect(bottomSheet.showDragHandle, isTrue);
    expect(sheetShell, findsOneWidget);
    expect(
      tester.getSize(sheetShell).height,
      closeTo(availableHeight * 0.75, 0.01),
    );
    expect(find.text('Select entry'), findsOneWidget);
    expect(find.text('Choose from the ledger.'), findsOneWidget);
    expect(find.text('Sheet content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
