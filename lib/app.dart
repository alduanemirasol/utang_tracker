import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/router/app_router.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';

final List<Locale> _supportedLocales = kMaterialSupportedLanguages
    .map((languageCode) => Locale(languageCode))
    .toList(growable: false);

class UtangTrackerApp extends StatefulWidget {
  const UtangTrackerApp({super.key});

  @override
  State<UtangTrackerApp> createState() => _UtangTrackerAppState();
}

class _UtangTrackerAppState extends State<UtangTrackerApp> {
  late final _router = createAppRouter();

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
