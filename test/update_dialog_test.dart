import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utang_tracker/core/update/app_update_checker.dart';
import 'package:utang_tracker/core/update/app_version.dart';
import 'package:utang_tracker/core/update/github_release_service.dart';
import 'package:utang_tracker/core/widgets/force_update_dialog.dart';

void main() {
  testWidgets('update dialog can be postponed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showUpdateDialog(
                context: context,
                currentVersion: const AppVersion(1, 0, 0),
                update: const GithubReleaseUpdate(
                  version: AppVersion(1, 0, 1),
                  tagName: 'v1.0.1',
                  apkUrl: 'https://example.com/app.apk',
                  apkName: 'app.apk',
                ),
              ),
              child: const Text('Show update'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show update'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);

    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsNothing);
  });

  testWidgets('app closes after the installer opens successfully', (
    tester,
  ) async {
    final platformCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showUpdateDialog(
                context: context,
                currentVersion: const AppVersion(1, 0, 0),
                update: const GithubReleaseUpdate(
                  version: AppVersion(1, 0, 1),
                  tagName: 'v1.0.1',
                  apkUrl: 'https://example.com/app.apk',
                  apkName: 'app.apk',
                ),
                checker: _SuccessfulUpdateChecker(),
              ),
              child: const Text('Show update'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show update'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update now'));
    await tester.pump();
    await tester.pump();

    expect(
      platformCalls.map((call) => call.method),
      contains('SystemNavigator.pop'),
    );
  });
}

class _SuccessfulUpdateChecker extends AppUpdateChecker {
  @override
  Future<void> downloadAndInstall(
    GithubReleaseUpdate update, {
    void Function(double? progress)? onProgress,
  }) async {
    onProgress?.call(1);
  }
}
