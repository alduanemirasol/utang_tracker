import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/notifications/domain/entities/debt_notification.dart';
import 'package:utang_tracker/features/notifications/presentation/providers/notification_providers.dart';

Future<String?> showDebtNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _DebtNotificationsSheet(),
  );
}

class _DebtNotificationsSheet extends ConsumerWidget {
  const _DebtNotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(debtNotificationsProvider);
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due reminders',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Debts that need attention now or within 7 days.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close reminders',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: notifications.when(
              loading: () =>
                  const LoadingIndicator(message: 'Checking due dates'),
              error: (error, _) => ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.read(debtNotificationsProvider.notifier).refresh(),
              ),
              data: (feed) => _NotificationLedger(feed: feed),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationLedger extends StatelessWidget {
  const _NotificationLedger({required this.feed});

  final DebtNotificationFeed feed;

  @override
  Widget build(BuildContext context) {
    if (feed.isEmpty) {
      return const _EmptyNotifications();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxl,
      ),
      children: [
        _AttentionSummary(feed: feed),
        const SizedBox(height: AppSpacing.xl),
        for (final kind in DebtNotificationKind.values) ...[
          if (feed.byKind(kind).isNotEmpty) ...[
            _NotificationSection(kind: kind, items: feed.byKind(kind)),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ],
    );
  }
}

class _AttentionSummary extends StatelessWidget {
  const _AttentionSummary({required this.feed});

  final DebtNotificationFeed feed;

  @override
  Widget build(BuildContext context) {
    final urgent = feed.urgentCount;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: urgent > 0 ? AppColors.unpaidBg : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            urgent > 0
                ? Icons.notification_important_outlined
                : Icons.event_available_outlined,
            color: urgent > 0 ? AppColors.unpaid : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              urgent > 0
                  ? '$urgent ${urgent == 1 ? 'debt needs' : 'debts need'} attention today'
                  : '${feed.items.length} ${feed.items.length == 1 ? 'debt is' : 'debts are'} coming due',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  const _NotificationSection({required this.kind, required this.items});

  final DebtNotificationKind kind;
  final List<DebtNotification> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _sectionLabel(kind),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: _foreground(kind)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _background(kind),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: _foreground(kind),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _NotificationRow(notification: items[index]),
                if (index != items.length - 1)
                  const Divider(indent: 64, endIndent: AppSpacing.lg),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final DebtNotification notification;

  @override
  Widget build(BuildContext context) {
    final kind = notification.kind;
    return InkWell(
      onTap: () => Navigator.pop(context, notification.debt.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _background(kind),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon(kind), size: 19, color: _foreground(kind)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.debt.customerName ?? 'Customer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_timingLabel(notification)} · ${DateFormatters.formatDate(notification.dueDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _foreground(kind),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MoneyText(notification.debt.balance),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.paidBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 32,
                color: AppColors.paid,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Nothing needs attention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Upcoming due dates will appear here seven days before they are due.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _sectionLabel(DebtNotificationKind kind) => switch (kind) {
  DebtNotificationKind.overdue => 'OVERDUE',
  DebtNotificationKind.dueToday => 'DUE TODAY',
  DebtNotificationKind.dueSoon => 'COMING UP',
};

String _timingLabel(DebtNotification notification) {
  return switch (notification.kind) {
    DebtNotificationKind.overdue =>
      '${notification.daysFromToday.abs()} ${notification.daysFromToday == -1 ? 'day' : 'days'} overdue',
    DebtNotificationKind.dueToday => 'Due today',
    DebtNotificationKind.dueSoon =>
      notification.daysFromToday == 1
          ? 'Due tomorrow'
          : 'Due in ${notification.daysFromToday} days',
  };
}

IconData _icon(DebtNotificationKind kind) => switch (kind) {
  DebtNotificationKind.overdue => Icons.warning_amber_rounded,
  DebtNotificationKind.dueToday => Icons.today_outlined,
  DebtNotificationKind.dueSoon => Icons.event_outlined,
};

Color _foreground(DebtNotificationKind kind) => switch (kind) {
  DebtNotificationKind.overdue => AppColors.unpaid,
  DebtNotificationKind.dueToday => AppColors.partial,
  DebtNotificationKind.dueSoon => AppColors.primary,
};

Color _background(DebtNotificationKind kind) => switch (kind) {
  DebtNotificationKind.overdue => AppColors.unpaidBg,
  DebtNotificationKind.dueToday => AppColors.partialBg,
  DebtNotificationKind.dueSoon => AppColors.primaryLight,
};
