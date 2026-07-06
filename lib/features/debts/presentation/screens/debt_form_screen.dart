import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';

class DebtFormScreen extends StatelessWidget {
  final String? debtId;
  final String? customerId;

  const DebtFormScreen({super.key, this.debtId, this.customerId});

  bool get isEditing => debtId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEditing ? 'Edit Debt' : 'New Debt')),
      body: const Center(child: Text('Debt Form')),
    );
  }
}
