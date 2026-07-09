import 'package:flutter/material.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/features/dashboard/domain/activity_item.dart';

class RecentActivityCard extends StatelessWidget {
  final List<ActivityItem> items;
  final ValueChanged<ActivityItem>? onItemTap;
  final String title;

  const RecentActivityCard({
    super.key,
    required this.items,
    this.onItemTap,
    this.title = 'Recent payments',
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      header: Text(
        title,
        style: const TextStyle(
          fontSize: AppFontSizes.xl,
          fontWeight: AppFontWeights.semibold,
          color: AppColors.textPrimary,
        ),
      ),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space5),
              child: Center(
                child: Text(
                  'No recent payments',
                  style: TextStyle(
                    fontSize: AppFontSizes.md,
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

    final row = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space5),
      child: Row(
        children: [
          Container(
            width: AppSpacing.space48,
            height: AppSpacing.space48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
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
                    fontSize: AppFontSizes.md,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '${item.statusLabel} · ${DateTimeHelper.formatDate(item.date)}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space5),
          AppMoneyText(
            amount: item.amount,
            size: AppMoneySize.md,
            color: isDebt ? AppColors.textPrimary : AppColors.success,
          ),
        ],
      ),
    );

    if (onItemTap == null) return row;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () => onItemTap!(item),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: row,
      ),
    );
  }
}
