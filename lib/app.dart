import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/router/app_router.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';
import 'package:utang_tracker/features/updater/presentation/providers/update_providers.dart';
import 'package:utang_tracker/features/updater/presentation/widgets/update_bottom_sheet.dart';

final List<Locale> _supportedLocales = kMaterialSupportedLanguages
    .map((languageCode) => Locale(languageCode))
    .toList(growable: false);

class UtangTrackerApp extends ConsumerStatefulWidget {
  const UtangTrackerApp({super.key});

  @override
  ConsumerState<UtangTrackerApp> createState() => _UtangTrackerAppState();
}

class _UtangTrackerAppState extends ConsumerState<UtangTrackerApp> {
  late final _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCheckForUpdates());
  }

  Future<void> _maybeCheckForUpdates() async {
    final repo = ref.read(updateRepositoryProvider);
    final lastCheck = await repo.loadLastCheckTime();
    final now = DateTime.now();

    if (lastCheck != null &&
        now.difference(lastCheck) < AppConstants.updateCheckThrottle) {
      return;
    }

    await ref
        .read(updateNotifierProvider.notifier)
        .checkForUpdates(silent: true);

    if (!mounted) return;
    final state = ref.read(updateNotifierProvider);
    if (state is UpdateAvailable) {
      await showUpdateBottomSheet(_router.routerDelegate.navigatorKey.currentContext!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: _supportedLocales,
      routerConfig: _router,
    );
  }
}
