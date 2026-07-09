import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/constants/app_breakpoints.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_confirm_dialog.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/core/presentation/app_page_body.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';
import 'package:utang_tracker/features/dashboard/presentation/widgets/total_receivables_card.dart';

void main() {
  group('AppBreakpoints', () {
    test('classifies compact, medium, expanded widths', () {
      expect(AppBreakpoints.widthClassFor(320), AppWidthClass.compact);
      expect(AppBreakpoints.widthClassFor(360), AppWidthClass.medium);
      expect(AppBreakpoints.widthClassFor(599), AppWidthClass.medium);
      expect(AppBreakpoints.widthClassFor(600), AppWidthClass.expanded);
      expect(AppBreakpoints.widthClassFor(800), AppWidthClass.expanded);
    });
  });

  group('AppResponsive', () {
    Future<AppResponsive> pumpResponsive(
      WidgetTester tester, {
      required Size size,
      double textScale = 1,
    }) async {
      late AppResponsive captured;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Builder(
            builder: (context) {
              captured = AppResponsive.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return captured;
    }

    testWidgets('compact padding and content width', (tester) async {
      final r = await pumpResponsive(tester, size: const Size(320, 568));
      expect(r.isCompact, isTrue);
      expect(r.horizontalPadding, AppSpacing.space5);
      expect(r.contentMaxWidth, AppSpacing.contentMaxWidth);
    });

    testWidgets('expanded padding and wide content width', (tester) async {
      final r = await pumpResponsive(tester, size: const Size(800, 1280));
      expect(r.isExpanded, isTrue);
      expect(r.horizontalPadding, AppSpacing.space10);
      expect(r.contentMaxWidth, AppSpacing.contentMaxWidthWide);
    });

    testWidgets('detects large text scale', (tester) async {
      final r = await pumpResponsive(
        tester,
        size: const Size(360, 800),
        textScale: 1.5,
      );
      expect(r.isLargeText, isTrue);
    });
  });

  group('Overflow-safe widgets', () {
    testWidgets('AppMoneyText builds at narrow width with large amount',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              child: AppMoneyText(
                amount: 1234567890.99,
                size: AppMoneySize.display,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(AppMoneyText), findsOneWidget);
    });

    testWidgets('AppPrimaryButton ellipsizes long labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              child: AppPrimaryButton(
                label: 'Pay remaining ₱1,234,567.89 now please',
                icon: Icons.done_all,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(AppPrimaryButton));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
    });

    testWidgets('AppConstrainedWidth clamps tablet content', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1280));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const contentKey = Key('constrained-content');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppConstrainedWidth(
              child: SizedBox(
                key: contentKey,
                width: double.infinity,
                height: 40,
                child: ColoredBox(color: Colors.red),
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byKey(contentKey));
      expect(box.size.width, lessThanOrEqualTo(AppSpacing.contentMaxWidthWide));
    });

    testWidgets('TotalReceivablesCard builds on 320dp', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TotalReceivablesCard(
                outstandingBalance: 9999999.99,
                totalCollected: 8888888.88,
                totalDebtAmount: 11111111.11,
                activeDebtCount: 42,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Outstanding balance'), findsOneWidget);
    });

    testWidgets('confirm dialog scrolls long content on small screens',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    AppConfirmDialog.show(
                      context,
                      title: 'Delete',
                      message: List.filled(40, 'Long message. ').join(),
                      isDestructive: true,
                    );
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('Multi-size smoke', () {
    final sizes = <Size>[
      const Size(320, 568),
      const Size(360, 800),
      const Size(412, 915),
      const Size(800, 1280),
      const Size(900, 400),
    ];

    for (final size in sizes) {
      testWidgets('money + button layout at $size', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const AppMoneyText(
                    amount: 1234567.89,
                    size: AppMoneySize.display,
                  ),
                  const SizedBox(height: 12),
                  AppPrimaryButton(
                    label: 'Record payment',
                    icon: Icons.payments_outlined,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  AppSecondaryButton(
                    label: 'Pay remaining ₱9,999,999.99',
                    icon: Icons.done_all,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('stats-like row under large text scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: const [
                  TotalReceivablesCard(
                    outstandingBalance: 50000,
                    totalCollected: 20000,
                    totalDebtAmount: 70000,
                    activeDebtCount: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
