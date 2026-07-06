import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';

class CustomerFormScreen extends StatelessWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  bool get isEditing => customerId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEditing ? 'Edit Customer' : 'New Customer')),
      body: const Center(child: Text('Customer Form')),
    );
  }
}
