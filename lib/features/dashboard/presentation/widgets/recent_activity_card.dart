import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/features/dashboard/domain/activity_item.dart';

class RecentActivityCard extends StatelessWidget {
  final List<ActivityItem> items;

  const RecentActivityCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      header: const Text(
        'Recent Activity',
        style: TextStyle(
          fontSize: AppFontSizes.lg,
          fontWeight: AppFontWeights.semibold,
          color: AppColors.textPrimary,
        ),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space5),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : Column(
              children: items.map(_buildItem).toList(),
            ),
    );
  }

  Widget _buildItem(ActivityItem item) {
    final isDebt = item.type == ActivityType.debt;
    final icon = isDebt ? Icons.shopping_cart_outlined : Icons.payments_outlined;
    final iconColor = isDebt ? AppColors.warning : AppColors.success;
    final iconBg = isDebt
        ? AppColors.warning.withValues(alpha: 0.1)
        : AppColors.success.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppSpacing.space3),
            ),
            child: Icon(icon, color: iconColor, size: AppFontSizes.iconSm),
          ),
          const SizedBox(width: AppSpacing.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.customerName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space05),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: isDebt
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.space1),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: AppFontSizes.xs - 1,
                          fontWeight: AppFontWeights.medium,
                          color: iconColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      DateTimeHelper.formatDate(item.date),
                      style: const TextStyle(
                        fontSize: AppFontSizes.xs - 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space5),
          Text(
            '₱${_formatAmount(item.amount)}',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.semibold,
              color: isDebt ? AppColors.textPrimary : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}
