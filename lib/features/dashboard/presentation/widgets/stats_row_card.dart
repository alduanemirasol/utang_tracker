import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_border_widths.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/features/dashboard/presentation/widgets/stat_item.dart';

class StatsRowCard extends StatelessWidget {
  final String customers;
  final String activeDebts;

  const StatsRowCard({
    super.key,
    required this.customers,
    required this.activeDebts,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: StatItem(
              icon: Icons.people_outline,
              label: 'Customers',
              value: customers,
            ),
          ),
          Container(width: AppBorderWidths.regular, height: AppSpacing.space40, color: AppColors.border),
          Expanded(
            child: StatItem(
              icon: Icons.receipt_long_outlined,
              label: 'Active Debts',
              value: activeDebts,
            ),
          ),
        ],
      ),
    );
  }
}
