import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';

class TotalCollectedCard extends StatelessWidget {
  final String amount;

  const TotalCollectedCard({
    super.key,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      header: Row(
        children: [
          Container(
            width: AppSpacing.space40,
            height: AppSpacing.space40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.xsm),
            ),
            child: const Icon(
              Icons.payments,
              color: AppColors.success,
              size: AppFontSizes.x2l,
            ),
          ),
          const SizedBox(width: AppSpacing.space5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Collected',
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space05),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: AppFontSizes.x2l,
                  fontWeight: AppFontWeights.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
