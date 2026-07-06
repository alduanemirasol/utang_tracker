import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(child: Text('Customer Detail')),
    );
  }
}
