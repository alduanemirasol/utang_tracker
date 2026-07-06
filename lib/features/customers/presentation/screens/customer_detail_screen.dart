import 'package:flutter/material.dart';

class CustomerDetailScreen extends StatelessWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Customer Detail')),
    );
  }
}
