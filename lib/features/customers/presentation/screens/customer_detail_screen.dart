import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.pushNamed(
              'customerEdit',
              pathParameters: {'id': customerId},
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: asyncSummary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space8),
            child: Text(
              'Failed to load customer',
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.error,
              ),
            ),
          ),
        ),
        data: (summary) {
          final customer = summary.customer;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.space7),
            children: [
              AppCard(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person,
                      label: customer.name,
                      isTitle: true,
                    ),
                    if (customer.phone case final phone?) ...[
                      const SizedBox(height: AppSpacing.space5),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: phone,
                      ),
                    ],
                    if (customer.notes case final notes?) ...[
                      const SizedBox(height: AppSpacing.space5),
                      _InfoRow(
                        icon: Icons.notes_outlined,
                        label: notes,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space5),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label:
                          'Member since ${DateTimeHelper.formatDate(customer.createdAt)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              _StatsRow(
                totalDebts: summary.totalDebts,
                totalBalance: summary.totalBalance,
                totalPaid: summary.totalPaid,
              ),
              if (summary.lastTransactionDate case final lastDate?) ...[
                const SizedBox(height: AppSpacing.space3),
                AppCard(
                  child: _InfoRow(
                    icon: Icons.history_outlined,
                    label: 'Last transaction ${DateTimeHelper.formatDate(lastDate)}',
                  ),
                ),
              ],
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
        title: const Text('Delete Customer'),
        content: const Text(
          'This will permanently delete this customer and all associated debts and payments.',
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
        await ref.read(deleteCustomerUseCaseProvider).execute(customerId);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(customerListProvider);
        context.showSuccessSnackBar('Customer deleted');
        context.pop();
      case Error(failure: final f):
        context.showErrorSnackBar(f.message);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isTitle;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.isTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            style: TextStyle(
              fontSize: isTitle ? AppFontSizes.xl : AppFontSizes.sm,
              fontWeight:
                  isTitle ? AppFontWeights.semibold : AppFontWeights.regular,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalDebts;
  final double totalBalance;
  final double totalPaid;

  const _StatsRow({
    required this.totalDebts,
    required this.totalBalance,
    required this.totalPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long_outlined,
            label: 'Debts',
            value: '$totalDebts',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _StatCard(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Balance',
            value: formatPeso(totalBalance),
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _StatCard(
            icon: Icons.payments_outlined,
            label: 'Paid',
            value: formatPeso(totalPaid),
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppFontSizes.iconSm),
          const SizedBox(height: AppSpacing.space3),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSizes.md,
              fontWeight: AppFontWeights.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space05),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.xs - 1,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
