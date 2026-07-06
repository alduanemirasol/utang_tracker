import 'package:flutter/material.dart';

class PaymentFormScreen extends StatelessWidget {
  final String debtId;
  final String? paymentId;

  const PaymentFormScreen({super.key, required this.debtId, this.paymentId});

  bool get isEditing => paymentId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Payment' : 'New Payment')),
      body: const Center(child: Text('Payment Form')),
    );
  }
}
