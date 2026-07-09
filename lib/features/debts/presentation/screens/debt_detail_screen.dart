import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_confirm_dialog.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/core/presentation/app_section_header.dart';
import 'package:utang_tracker/core/presentation/app_status_badge.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class DebtDetailScreen extends ConsumerWidget {
  final String debtId;

  const DebtDetailScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(debtDetailProvider(debtId));
    final asyncCustomers = ref.watch(customerListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Debt'),
        actions: [
          TextButton(
            onPressed: () => context.pushNamed(
              'debtEdit',
              pathParameters: {'id': debtId},
            ),
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () => _confirmDelete(context, ref),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
      body: asyncDetail.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppErrorView(
          message: 'Failed to load debt',
          onRetry: () => ref.invalidate(debtDetailProvider(debtId)),
        ),
        data: (detail) {
          final debt = detail.debt;
          final customerNames = asyncCustomers.asData?.value ?? [];
          final nameMap = {for (final c in customerNames) c.id: c.name};
          final customerName = nameMap[debt.customerId] ?? 'Unknown';
          final canPay = debt.balance > 0.001;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.space7),
            children: [
              _DebtHeroCard(
                customerName: customerName,
                totalAmount: debt.totalAmount,
                paidAmount: debt.paidAmount,
                balance: debt.balance,
                status: debt.status,
                transactionDate: debt.transactionDate,
                dueDate: debt.dueDate,
                notes: debt.notes,
              ),
              if (canPay) ...[
                const SizedBox(height: AppSpacing.space3),
                AppPrimaryButton(
                  label: 'Record payment',
                  icon: Icons.payments_outlined,
                  onPressed: () => context.pushNamed(
                    'paymentNew',
                    pathParameters: {'id': debtId},
                  ),
                ),
                const SizedBox(height: AppSpacing.space5),
                AppSecondaryButton(
                  label: 'Pay remaining ${formatPeso(debt.balance)}',
                  icon: Icons.done_all,
                  onPressed: () => context.pushNamed(
                    'paymentNew',
                    pathParameters: {'id': debtId},
                    queryParameters: {
                      'amount': debt.balance.toString(),
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.space3),
                AppCard(
                  backgroundColor: AppColors.success.withValues(alpha: 0.1),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: AppSpacing.space5),
                      Expanded(
                        child: Text(
                          'This debt is fully paid',
                          style: TextStyle(
                            fontSize: AppFontSizes.lg,
                            fontWeight: AppFontWeights.semibold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space8),
              AppSectionHeader(
                label: 'Items',
                count: detail.items.length,
                actionLabel: 'Add item',
                onAction: () => context.pushNamed(
                  'debtItemNew',
                  pathParameters: {'id': debtId},
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              if (detail.items.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        color: AppColors.textSecondary,
                        size: AppFontSizes.iconMd,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      const Text(
                        'No items added yet',
                        style: TextStyle(
                          fontSize: AppFontSizes.md,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space5),
                      TextButton(
                        onPressed: () => context.pushNamed(
                          'debtItemNew',
                          pathParameters: {'id': debtId},
                        ),
                        child: const Text('Add item'),
                      ),
                    ],
                  ),
                )
              else
                ...detail.items.map(
                  (item) => _ItemTile(
                    productName: item.productName,
                    quantity: item.quantity,
                    unit: item.unit,
                    unitPrice: item.unitPrice,
                    subtotal: item.subtotal,
                    onTap: () => context.pushNamed(
                      'debtItemEdit',
                      pathParameters: {
                        'id': debtId,
                        'itemId': item.id,
                      },
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.space7),
              AppSectionHeader(
                label: 'Payments',
                count: detail.payments.length,
                actionLabel: canPay ? 'Add' : null,
                onAction: canPay
                    ? () => context.pushNamed(
                          'paymentNew',
                          pathParameters: {'id': debtId},
                        )
                    : null,
              ),
              const SizedBox(height: AppSpacing.space5),
              if (detail.payments.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.textSecondary,
                        size: AppFontSizes.iconMd,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      const Text(
                        'No payments recorded',
                        style: TextStyle(
                          fontSize: AppFontSizes.md,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (canPay) ...[
                        const SizedBox(height: AppSpacing.space5),
                        TextButton(
                          onPressed: () => context.pushNamed(
                            'paymentNew',
                            pathParameters: {'id': debtId},
                          ),
                          child: const Text('Record payment'),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ...detail.payments.map(
                  (payment) => _PaymentTile(
                    amount: payment.amount,
                    paymentDate: payment.paymentDate,
                    method: payment.paymentMethod.value,
                    onTap: () => context.pushNamed(
                      'paymentEdit',
                      pathParameters: {
                        'id': debtId,
                        'paymentId': payment.id,
                      },
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.space10),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete Debt',
      message:
          'This will permanently delete this debt and all associated items and payments.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    final result = await ref.read(deleteDebtUseCaseProvider).execute(debtId);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(debtListProvider);
        ref.invalidate(allDebtsProvider);
        ref.invalidate(dashboardProvider);
        context.showSuccessSnackBar('Debt deleted');
        context.pop();
      case Error(failure: final f):
        context.showErrorSnackBar(f.message);
    }
  }
}

class _DebtHeroCard extends StatelessWidget {
  final String customerName;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final DebtStatus status;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final String? notes;

  const _DebtHeroCard({
    required this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.balance,
    required this.status,
    required this.transactionDate,
    this.dueDate,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.x2l,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              AppStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.space7),
          const Text(
            'Remaining balance',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          AppMoneyText(
            amount: balance,
            size: AppMoneySize.display,
            color: balance > 0 ? AppColors.textPrimary : AppColors.success,
          ),
          const SizedBox(height: AppSpacing.space7),
          Row(
            children: [
              Expanded(
                child: _AmountColumn(label: 'Total', amount: totalAmount),
              ),
              Expanded(
                child: _AmountColumn(
                  label: 'Paid',
                  amount: paidAmount,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space7),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date: ${DateTimeHelper.formatDate(transactionDate)}',
          ),
          if (dueDate case final d?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space3),
              child: _InfoRow(
                icon: Icons.event_outlined,
                label: 'Due: ${DateTimeHelper.formatDate(d)}',
              ),
            ),
          if (notes case final n?)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space3),
              child: _InfoRow(
                icon: Icons.notes_outlined,
                label: n,
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color? color;

  const _AmountColumn({
    required this.label,
    required this.amount,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSizes.sm,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        AppMoneyText(
          amount: amount,
          size: AppMoneySize.md,
          color: color,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppFontSizes.iconSm, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.space5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final String productName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double subtotal;
  final VoidCallback onTap;

  const _ItemTile({
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.subtotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '${formatQuantity(quantity)} $unit × ${formatPeso(unitPrice)}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppMoneyText(amount: subtotal, size: AppMoneySize.md),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final double amount;
  final DateTime paymentDate;
  final String method;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.amount,
    required this.paymentDate,
    required this.method,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateTimeHelper.formatDate(paymentDate),
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  method,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppMoneyText(
            amount: amount,
            size: AppMoneySize.md,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}
