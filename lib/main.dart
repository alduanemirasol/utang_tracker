import 'package:flutter/material.dart';
import 'package:utang_tracker/core/database/app_database.dart';
import 'core/helpers/date_time_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DateTimeHelper.initialize();
  await AppDatabase().init();
  runApp(const UtangTrackerApp());
}

class UtangTrackerApp extends StatelessWidget {
  const UtangTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Utang Tracker',
      home: const Scaffold(body: Center(child: Text('Utang Tracker'))),
    );
  }
}
