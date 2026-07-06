import 'package:flutter/material.dart';

class CustomerFormScreen extends StatelessWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  bool get isEditing => customerId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Customer' : 'New Customer')),
      body: const Center(child: Text('Customer Form')),
    );
  }
}
