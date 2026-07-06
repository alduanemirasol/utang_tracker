import 'package:flutter/material.dart';

class DebtItemFormScreen extends StatelessWidget {
  final String debtId;
  final String? itemId;

  const DebtItemFormScreen({super.key, required this.debtId, this.itemId});

  bool get isEditing => itemId != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'New Item')),
      body: const Center(child: Text('Debt Item Form')),
    );
  }
}
