import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_header.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/features/dashboard/domain/activity_item.dart';
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
        loading: () => const AppLoadingView(message: 'Loading dashboard...'),
        error: (e, _) => AppErrorView(
          message: 'Failed to load dashboard',
          onRetry: () => ref.invalidate(dashboardProvider),
        ),
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space7),
              children: [
                const AppHeader(
                  label: 'Dashboard',
                  subtitle: 'Your debt overview',
                  padding: EdgeInsets.only(bottom: AppSpacing.space7),
                ),
                TotalReceivablesCard(
                  outstandingBalance: summary.totalOutstandingBalance,
                  totalCollected: summary.totalCollected,
                  totalDebtAmount: summary.totalDebtAmount,
                  activeDebtCount: summary.activeDebtCount,
                ),
                if (summary.overdueCount > 0)
                  AppCard(
                    backgroundColor: AppColors.error.withValues(alpha: 0.08),
                    onTap: () => context.goNamed('debtList'),
                    child: Row(
                      children: [
                        Container(
                          width: AppSpacing.space48,
                          height: AppSpacing.space48,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                            size: AppFontSizes.iconMd,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${summary.overdueCount} overdue debt${summary.overdueCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.lg,
                                  fontWeight: AppFontWeights.semibold,
                                  color: AppColors.error,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.space1),
                              AppMoneyText(
                                amount: summary.overdueAmount,
                                size: AppMoneySize.md,
                                color: AppColors.error,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.error,
                          size: AppFontSizes.iconMd,
                        ),
                      ],
                    ),
                  ),
                _QuickActions(
                  onAddDebt: () => context.pushNamed('debtNew'),
                  onAddCustomer: () => context.pushNamed('customerNew'),
                  onRecordPayment: () => context.goNamed('debtList'),
                ),
                if (summary.upcomingDues.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space3),
                  AppCard(
                    header: const Text(
                      'Upcoming due dates',
                      style: TextStyle(
                        fontSize: AppFontSizes.xl,
                        fontWeight: AppFontWeights.semibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    child: Column(
                      children: summary.upcomingDues.map((item) {
                        return Material(
                          color: AppColors.transparent,
                          child: InkWell(
                            onTap: () => context.pushNamed(
                              'debtDetail',
                              pathParameters: {'id': item.debtId},
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.space5,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          'Due ${DateTimeHelper.formatDate(item.dueDate)}',
                                          style: const TextStyle(
                                            fontSize: AppFontSizes.sm,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppMoneyText(
                                    amount: item.balance,
                                    size: AppMoneySize.md,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                RecentActivityCard(
                  items: summary.recentPayments,
                  onItemTap: (ActivityItem item) {
                    context.pushNamed(
                      'debtDetail',
                      pathParameters: {'id': item.debtId},
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onAddDebt;
  final VoidCallback onAddCustomer;
  final VoidCallback onRecordPayment;

  const _QuickActions({
    required this.onAddDebt,
    required this.onAddCustomer,
    required this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space5),
      child: Row(
        children: [
          Expanded(
            child: _ActionChip(
              icon: Icons.receipt_long,
              label: 'Add debt',
              onTap: onAddDebt,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: _ActionChip(
              icon: Icons.person_add_alt_1,
              label: 'Add customer',
              onTap: onAddCustomer,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: _ActionChip(
              icon: Icons.payments,
              label: 'Payments',
              onTap: onRecordPayment,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSpacing.space64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space3,
              vertical: AppSpacing.space5,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: AppFontSizes.iconMd),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
