import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(child: Text('Customer List')),
    );
  }
}
