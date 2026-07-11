import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/router/app_router.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/core/update/app_update_checker.dart';
import 'package:utang_tracker/core/widgets/force_update_dialog.dart';

class UtangTrackerApp extends ConsumerStatefulWidget {
  const UtangTrackerApp({super.key});

  @override
  ConsumerState<UtangTrackerApp> createState() => _UtangTrackerAppState();
}

class _UtangTrackerAppState extends ConsumerState<UtangTrackerApp> {
  late final _router = createAppRouter();
  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_updateCheckStarted) return;
    _updateCheckStarted = true;

    // Let the first route paint before showing a dialog.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final checker = AppUpdateChecker();
    try {
      final result = await checker.checkForUpdate();
      if (!mounted) {
        checker.dispose();
        return;
      }
      if (!result.isUpdateAvailable || result.update == null) {
        checker.dispose();
        return;
      }

      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        checker.dispose();
        return;
      }

      await showForceUpdateDialog(
        context: ctx,
        currentVersion: result.currentVersion,
        update: result.update!,
        checker: checker,
      );
    } catch (_) {
      // Fail open: network/API errors must not block app use.
      checker.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
