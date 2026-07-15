import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/recent_activity_item.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_notification.dart';
import 'package:utang_tracker/features/notifications/presentation/providers/notification_providers.dart';
import 'package:utang_tracker/features/notifications/presentation/widgets/debt_notifications_sheet.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardSummaryProvider);
    final notifications = ref.watch(debtNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          _NotificationAction(
            notifications: notifications,
            onTap: () async {
              final debtId = await showDebtNotificationsSheet(context);
              if (debtId == null || !context.mounted) return;
              context.push('/debts/$debtId');
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'Opening your ledger'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(dashboardSummaryProvider.notifier).refresh(),
                ref.read(debtNotificationsProvider.notifier).refresh(),
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                AppSpacing.xxl,
              ),
              children: [
                _LedgerBalanceCard(
                  balance: summary.outstandingBalance,
                  activeDebts: summary.activeDebtsCount,
                  collectedToday: summary.collectedToday,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'New utang',
                        color: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        onTap: () => context.push('/debts/new'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Bayad',
                        color: AppColors.surfaceCard,
                        foregroundColor: AppColors.primaryDark,
                        onTap: () => context.push('/payments/new'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionHeader(
                  title: 'Recent activity',
                  actionLabel: summary.recentActivity.isEmpty
                      ? null
                      : 'View debts',
                  onAction: () => context.go('/debts'),
                ),
                const SizedBox(height: AppSpacing.md),
                if (summary.recentActivity.isEmpty)
                  const _EmptyActivity()
                else
                  _ActivityLedger(items: summary.recentActivity),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationAction extends StatelessWidget {
  const _NotificationAction({required this.notifications, required this.onTap});

  final AsyncValue<DebtNotificationFeed> notifications;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final urgentCount = notifications.value?.urgentCount ?? 0;
    final label = urgentCount > 0
        ? 'Due reminders, $urgentCount urgent'
        : 'Due reminders';

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: IconButton(
        tooltip: label,
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_rounded),
            if (urgentCount > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    urgentCount > 99 ? '99+' : '$urgentCount',
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LedgerBalanceCard extends StatelessWidget {
  const _LedgerBalanceCard({
    required this.balance,
    required this.activeDebts,
    required this.collectedToday,
  });

  final Money balance;
  final int activeDebts;
  final Money collectedToday;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: AppColors.primaryDark,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Receivables',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textOnPrimaryMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              MoneyText(
                balance,
                color: AppColors.textOnPrimary,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 36,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _DashedRule(),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Debts',
                          style: TextStyle(
                            color: AppColors.textOnPrimarySoft,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$activeDebts',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textOnPrimary,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Collected Today',
                          style: TextStyle(
                            color: AppColors.textOnPrimarySoft,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: MoneyText(
                            collectedToday,
                            color: AppColors.accent,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const gapWidth = 6.0;
        final count = (constraints.maxWidth / (dashWidth + gapWidth)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dashWidth,
              height: 1,
              child: ColoredBox(color: AppColors.primaryDivider),
            ),
          ),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.foregroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color == AppColors.surfaceCard
              ? AppColors.outline
              : AppColors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 23),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _ActivityLedger extends StatelessWidget {
  const _ActivityLedger({required this.items});

  final List<RecentActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _ActivityRow(
                item: items[i],
                onTap: () => context.push('/debts/${items[i].debtId}'),
              ),
              if (i != items.length - 1)
                const Divider(
                  height: AppSpacing.md,
                  indent: 66,
                  endIndent: AppSpacing.md,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.onTap});

  final RecentActivityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPayment = item.type == RecentActivityType.payment;
    final color = isPayment ? AppColors.paid : AppColors.unpaid;
    final background = isPayment ? AppColors.paidBg : AppColors.unpaidBg;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isPayment
                    ? Icons.arrow_downward_rounded
                    : Icons.receipt_long_outlined,
                size: 19,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item.type.label} · ${DateFormatters.formatDate(item.date)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MoneyText(item.amount, color: color),
          ],
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceRaised,
      child: const Row(
        children: [
          Icon(Icons.history_rounded, color: AppColors.textMuted),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Your newest debts and payments will appear here.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
