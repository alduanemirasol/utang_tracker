import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_header.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/widgets/recent_activity_card.dart';
import 'package:utang_tracker/features/dashboard/presentation/widgets/total_receivables_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(dashboardProvider);

    return Container(
      color: AppColors.background,
      child: asyncSummary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space8),
            child: Text(
              'Failed to load dashboard',
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.error,
              ),
            ),
          ),
        ),
        data: (summary) {
          final outstanding = summary.totalOutstandingBalance;
          final collected = summary.totalCollected;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.space7),
            children: [
              AppHeader(
                label: 'Dashboard',
                rightIcon: Icons.notifications_outlined,
                onRightTap: () {},
                padding: const EdgeInsets.only(bottom: AppSpacing.space7),
              ),
              TotalReceivablesCard(
                totalReceivables: '₱${_formatAmount(outstanding)}',
                collectedThisMonth: '₱${_formatAmount(collected)}',
                activeCustomers: summary.totalCustomers,
              ),
              RecentActivityCard(items: summary.recentActivity),
            ],
          );
        },
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
