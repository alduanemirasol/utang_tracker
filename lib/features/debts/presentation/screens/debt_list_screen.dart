import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(child: Text('Debt List')),
    );
  }
}
