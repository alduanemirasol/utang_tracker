import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';

class TotalReceivablesCard extends StatelessWidget {
  final String totalReceivables;
  final String collectedThisMonth;
  final int activeCustomers;

  const TotalReceivablesCard({
    super.key,
    required this.totalReceivables,
    required this.collectedThisMonth,
    required this.activeCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primary,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL RECEIVABLES',
            style: TextStyle(
              fontSize: AppFontSizes.xs,
              fontWeight: AppFontWeights.medium,
              letterSpacing: 1.2,
              color: AppColors.onPrimaryLow,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            totalReceivables,
            style: const TextStyle(
              fontSize: AppFontSizes.x3l,
              fontWeight: AppFontWeights.bold,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COLLECTED THIS MONTH',
                      style: TextStyle(
                        fontSize: AppFontSizes.xs,
                        fontWeight: AppFontWeights.medium,
                        color: AppColors.onPrimaryLow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      collectedThisMonth,
                      style: const TextStyle(
                        fontSize: AppFontSizes.xl,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'ACTIVE CUSTOMERS',
                      style: TextStyle(
                        fontSize: AppFontSizes.xs,
                        fontWeight: AppFontWeights.medium,
                        color: AppColors.onPrimaryLow,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      '$activeCustomers',
                      style: const TextStyle(
                        fontSize: AppFontSizes.xl,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
