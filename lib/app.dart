import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/router.dart';
import 'package:utang_tracker/core/theme/app_theme.dart';

class App {
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    DateTimeHelper.initialize();
    await AppDatabase().init();
    runApp(const ProviderScope(child: UtangTrackerApp()));
  }
}

class UtangTrackerApp extends StatelessWidget {
  const UtangTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Utang Tracker',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
