import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';

class TotalReceivablesCard extends StatelessWidget {
  final double outstandingBalance;
  final double totalCollected;
  final double totalDebtAmount;
  final int activeDebtCount;

  const TotalReceivablesCard({
    super.key,
    required this.outstandingBalance,
    required this.totalCollected,
    required this.totalDebtAmount,
    required this.activeDebtCount,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Outstanding balance',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.medium,
              color: AppColors.onPrimaryLow,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          AppMoneyText(
            amount: outstandingBalance,
            size: AppMoneySize.display,
            color: AppColors.onPrimary,
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Total collected',
                  amount: totalCollected,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Total debts',
                  amount: totalDebtAmount,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          Text(
            '$activeDebtCount active debt${activeDebtCount == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.medium,
              color: AppColors.onPrimaryLow,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final double amount;
  final bool alignEnd;

  const _Metric({
    required this.label,
    required this.amount,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.sm,
            fontWeight: AppFontWeights.medium,
            color: AppColors.onPrimaryLow,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        AppMoneyText(
          amount: amount,
          size: AppMoneySize.lg,
          color: AppColors.onPrimary,
        ),
      ],
    );
  }
}
