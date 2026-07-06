import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_header.dart';
import 'package:utang_tracker/features/dashboard/presentation/widgets/stats_row_card.dart';
import 'package:utang_tracker/features/dashboard/presentation/widgets/total_collected_card.dart';
import 'package:utang_tracker/features/dashboard/presentation/widgets/total_receivables_card.dart';

const String totalReceivables = '₱1,055,000.00';
const String collectedThisMonth = '₱19,800';
const int activeCustomers = 43;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.space7),
        children: [
          AppHeader(
            label: 'Dashboard',
            rightIcon: Icons.notifications_outlined,
            onRightTap: () {},
            padding: const EdgeInsets.only(bottom: AppSpacing.space7),
          ),
          TotalReceivablesCard(
            totalReceivables: totalReceivables,
            collectedThisMonth: collectedThisMonth,
            activeCustomers: activeCustomers,
          ),
          const TotalCollectedCard(amount: '₱0.00'),
          const StatsRowCard(customers: '0', activeDebts: '0'),
        ],
      ),
    );
  }
}
