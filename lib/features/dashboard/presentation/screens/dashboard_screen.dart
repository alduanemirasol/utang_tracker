import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(child: Text('Dashboard')),
    );
  }
}
