import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/money.dart';
import 'package:utang_tracker/core/widgets/app_button.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/core/widgets/status_badge.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_item_unit.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class DebtDetailPage extends ConsumerWidget {
  const DebtDetailPage({super.key, required this.debtId});

  final String debtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(debtDetailProvider(debtId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Debt')),
        body: const LoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Debt')),
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(debtDetailProvider(debtId)),
        ),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Debt')),
            body: const Center(child: Text('Debt not found')),
          );
        }

        final debt = data.detail.debt;
        final items = data.detail.items;
        final payments = data.payments;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Debt details'),
            actions: [
              if (debt.isEditable)
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/debts/$debtId/edit'),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(debtDetailProvider(debtId));
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('/customers/${debt.customerId}'),
                              child: Text(
                                debt.customerName ?? 'Customer',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                          StatusBadge(status: debt.status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _kv(
                        context,
                        'Date',
                        DateFormatters.formatDateTime(debt.transactionDate),
                        valueAlignRight: true,
                      ),
                      if (debt.dueDate != null)
                        _kv(
                          context,
                          'Due date',
                          DateFormatters.formatDate(debt.dueDate!),
                          valueAlignRight: true,
                        ),
                      const Divider(height: AppSpacing.xl),
                      _amountRow(context, 'Total', debt.totalAmount),
                      _amountRow(context, 'Paid', debt.paidAmount),
                      _amountRow(
                        context,
                        'Balance',
                        debt.balance,
                        emphasize: true,
                      ),
                      if (debt.notes != null && debt.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          debt.notes!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (debt.status != DebtStatus.paid) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Record payment',
                    icon: Icons.payments_outlined,
                    onPressed: () =>
                        context.push('/payments/new?debtId=$debtId'),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text('Items', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _DebtItemsCard(items: items, totalAmount: debt.totalAmount),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Payments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (payments.isEmpty)
                  const Center(
                    child: Text(
                      'No payments yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...payments.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatters.formatDateTime(
                                      p.paymentDate,
                                    ),
                                  ),
                                  Text(
                                    p.paymentMethod,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            MoneyText(p.amount, color: AppColors.paid),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kv(
    BuildContext context,
    String k,
    String v, {
    bool valueAlignRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              k,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              v,
              textAlign: valueAlignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    Money money, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          MoneyText(
            money,
            style: emphasize
                ? Theme.of(context).textTheme.titleMedium
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _DebtItemsCard extends StatelessWidget {
  const _DebtItemsCard({required this.items, required this.totalAmount});

  final List<DebtItem> items;
  final Money totalAmount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const Key('debt-items-card'),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _DebtItemRow(item: items[index]),
            if (index < items.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.cardPadding,
                endIndent: AppSpacing.cardPadding,
              ),
          ],
          const Divider(height: 1),
          Padding(
            key: const Key('debt-items-total-row'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                MoneyText(
                  totalAmount,
                  key: const Key('debt-items-total-amount'),
                  color: AppColors.primaryDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtItemRow extends StatelessWidget {
  const _DebtItemRow({required this.item});

  final DebtItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final descriptionStyle =
        textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final subtotalStyle = textTheme.bodyLarge ?? const TextStyle(fontSize: 16);
    final quantityAndUnit =
        '${_formatQuantity(item.quantity)} '
        '${DebtItemUnits.displayName(item.unit)}';

    return Padding(
      key: ValueKey('debt-item-row-${item.id}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  key: ValueKey('debt-item-name-${item.id}'),
                  style: descriptionStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  quantityAndUnit,
                  key: ValueKey('debt-item-meta-${item.id}'),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          MoneyText(
            item.price,
            key: ValueKey('debt-item-subtotal-${item.id}'),
            style: subtotalStyle,
          ),
        ],
      ),
    );
  }
}

String _formatQuantity(double quantity) {
  if (quantity % 1 == 0) return quantity.toInt().toString();
  return quantity.toString();
}
