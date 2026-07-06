import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
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
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.pushNamed(
              'debtEdit',
              pathParameters: {'id': debtId},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space8),
            child: Text(
              'Failed to load debt',
              style: TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.error,
              ),
            ),
          ),
        ),
        data: (detail) {
          final debt = detail.debt;
          final customerNames = asyncCustomers.asData?.value ?? [];
          final nameMap = {
            for (final c in customerNames) c.id: c.name,
          };
          final customerName =
              nameMap[debt.customerId] ?? 'Unknown';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.space7),
            children: [
              _DebtInfoCard(
                customerName: customerName,
                totalAmount: debt.totalAmount,
                paidAmount: debt.paidAmount,
                balance: debt.balance,
                status: debt.status,
                transactionDate: debt.transactionDate,
                dueDate: debt.dueDate,
                notes: debt.notes,
              ),
              const SizedBox(height: AppSpacing.space7),
              _SectionHeader(
                label: 'Items',
                count: detail.items.length,
                onAdd: () => context.pushNamed(
                  'debtItemNew',
                  pathParameters: {'id': debtId},
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              if (detail.items.isEmpty)
                _EmptySection(
                  icon: Icons.shopping_cart_outlined,
                  message: 'No items added yet',
                  onAddLabel: 'Add Item',
                  onAdd: () => context.pushNamed(
                    'debtItemNew',
                    pathParameters: {'id': debtId},
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
              _SectionHeader(
                label: 'Payments',
                count: detail.payments.length,
                onAdd: () => context.pushNamed(
                  'paymentNew',
                  pathParameters: {'id': debtId},
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              if (detail.payments.isEmpty)
                _EmptySection(
                  icon: Icons.payments_outlined,
                  message: 'No payments recorded',
                  onAddLabel: 'Add Payment',
                  onAdd: () => context.pushNamed(
                    'paymentNew',
                    pathParameters: {'id': debtId},
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
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Debt'),
        content: const Text(
          'This will permanently delete this debt and all associated items and payments.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result =
        await ref.read(deleteDebtUseCaseProvider).execute(debtId);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(debtListProvider);
        context.showSuccessSnackBar('Debt deleted');
        context.pop();
      case Error(failure: final f):
        context.showErrorSnackBar(f.message);
    }
  }
}

class _DebtInfoCard extends StatelessWidget {
  final String customerName;
  final double totalAmount;
  final double paidAmount;
  final double balance;
  final DebtStatus status;
  final DateTime transactionDate;
  final DateTime? dueDate;
  final String? notes;

  const _DebtInfoCard({
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
    final statusColor = switch (status) {
      DebtStatus.unpaid => AppColors.error,
      DebtStatus.partial => AppColors.warning,
      DebtStatus.paid => AppColors.success,
    };
    final statusLabel = switch (status) {
      DebtStatus.unpaid => 'Unpaid',
      DebtStatus.partial => 'Partial',
      DebtStatus.paid => 'Paid',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.xl,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space05,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.xs,
                    fontWeight: AppFontWeights.semibold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space7),
          Row(
            children: [
              _AmountColumn(label: 'Total', amount: totalAmount),
              const SizedBox(width: AppSpacing.space8),
              _AmountColumn(
                label: 'Paid',
                amount: paidAmount,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.space8),
              _AmountColumn(
                label: 'Balance',
                amount: balance,
                color: balance > 0 ? statusColor : AppColors.success,
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.xs - 1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            formatPeso(amount),
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.bold,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
        Icon(
          icon,
          size: AppFontSizes.iconSm,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.space5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label ($count)',
          style: const TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: AppFontWeights.semibold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: AppFontSizes.iconSm),
          label: const Text('Add'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontWeight: AppFontWeights.semibold,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;
  final String onAddLabel;
  final VoidCallback onAdd;

  const _EmptySection({
    required this.icon,
    required this.message,
    required this.onAddLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: AppFontSizes.x2l),
          const SizedBox(height: AppSpacing.space3),
          Text(
            message,
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          TextButton(
            onPressed: onAdd,
            child: Text(onAddLabel),
          ),
        ],
      ),
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
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '${formatQuantity(quantity)} $unit × ${formatPeso(unitPrice)}',
                  style: const TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPeso(subtotal),
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.semibold,
              color: AppColors.textPrimary,
            ),
          ),
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
                    fontSize: AppFontSizes.sm,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  method,
                  style: const TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPeso(amount),
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: AppFontWeights.semibold,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
