import 'package:flutter/material.dart';

class DebtDetailScreen extends StatelessWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Debt Detail')),
    );
  }
}
