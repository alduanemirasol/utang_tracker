import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/recent_activity_item.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(dashboardSummaryProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                Text(
                  'Store overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Receivables',
                        child: MoneyText(
                          summary.outstandingBalance,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          color: summary.outstandingBalance.isZero
                              ? AppColors.paid
                              : AppColors.unpaid,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        label: 'Collected today',
                        child: MoneyText(
                          summary.collectedToday,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          color: AppColors.paid,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Active debts',
                        child: Text(
                          '${summary.activeDebtsCount}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _StatCard(
                        label: 'Customers',
                        child: Text(
                          '${summary.totalCustomers}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Recent activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                if (summary.recentActivity.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No activity yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...summary.recentActivity.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: () => context.push('/debts/${item.debtId}'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.customerName,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormatters.formatDate(item.date),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                MoneyText(
                                  item.amount,
                                  color: item.type == RecentActivityType.payment
                                      ? AppColors.paid
                                      : AppColors.unpaid,
                                ),
                                const SizedBox(height: 4),
                                _ActivityTypeBadge(type: item.type),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityTypeBadge extends StatelessWidget {
  const _ActivityTypeBadge({required this.type});

  final RecentActivityType type;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      RecentActivityType.debt => (AppColors.unpaidBg, AppColors.unpaid),
      RecentActivityType.payment => (AppColors.paidBg, AppColors.paid),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}
