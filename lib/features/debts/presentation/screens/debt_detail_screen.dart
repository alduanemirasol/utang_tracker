import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';

class DebtDetailScreen extends StatelessWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(child: Text('Debt Detail')),
    );
  }
}
