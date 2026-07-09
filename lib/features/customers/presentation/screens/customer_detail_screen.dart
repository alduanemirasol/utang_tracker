import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_button.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_confirm_dialog.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/core/presentation/app_section_header.dart';
import 'package:utang_tracker/core/presentation/app_status_badge.dart';
import 'package:utang_tracker/core/utils/snackbar_helper.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(customerDetailProvider(customerId));
    final asyncDebts = ref.watch(allDebtsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer'),
        actions: [
          TextButton(
            onPressed: () => context.pushNamed(
              'customerEdit',
              pathParameters: {'id': customerId},
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
      body: asyncSummary.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppErrorView(
          message: 'Failed to load customer',
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
        data: (summary) {
          final customer = summary.customer;
          final allDebts = asyncDebts.asData?.value ?? [];
          final customerDebts =
              allDebts.where((d) => d.customerId == customerId).toList()
                ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.space7),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: AppFontSizes.x2l,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (customer.phone case final phone?) ...[
                      const SizedBox(height: AppSpacing.space5),
                      _InfoRow(icon: Icons.phone_outlined, label: phone),
                    ],
                    if (customer.notes case final notes?) ...[
                      const SizedBox(height: AppSpacing.space5),
                      _InfoRow(icon: Icons.notes_outlined, label: notes),
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
              const SizedBox(height: AppSpacing.space7),
              AppPrimaryButton(
                label: 'Add debt',
                icon: Icons.receipt_long,
                onPressed: () => context.pushNamed(
                  'debtNew',
                  queryParameters: {'customerId': customerId},
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              AppSectionHeader(
                label: 'Debts',
                count: customerDebts.length,
              ),
              const SizedBox(height: AppSpacing.space5),
              if (asyncDebts.isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.space8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (customerDebts.isEmpty)
                AppCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.textSecondary,
                        size: AppFontSizes.iconMd,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      const Text(
                        'No debts for this customer',
                        style: TextStyle(
                          fontSize: AppFontSizes.md,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space5),
                      TextButton(
                        onPressed: () => context.pushNamed(
                          'debtNew',
                          queryParameters: {'customerId': customerId},
                        ),
                        child: const Text('Add debt'),
                      ),
                    ],
                  ),
                )
              else
                ...customerDebts.map(
                  (debt) => _CustomerDebtTile(
                    debt: debt,
                    onTap: () => context.pushNamed(
                      'debtDetail',
                      pathParameters: {'id': debt.id},
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
      title: 'Delete Customer',
      message:
          'This will permanently delete this customer and all associated debts and payments.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    final result =
        await ref.read(deleteCustomerUseCaseProvider).execute(customerId);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        ref.invalidate(customerListProvider);
        ref.invalidate(debtListProvider);
        ref.invalidate(allDebtsProvider);
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

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            label: 'Debts',
            value: '$totalDebts',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _StatCard(
            label: 'Balance',
            amount: totalBalance,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.space3),
        Expanded(
          child: _StatCard(
            label: 'Paid',
            amount: totalPaid,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String? value;
  final double? amount;
  final Color color;

  const _StatCard({
    required this.label,
    this.value,
    this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          if (amount != null)
            AppMoneyText(
              amount: amount!,
              size: AppMoneySize.sm,
              color: AppColors.textPrimary,
            )
          else
            Text(
              value ?? '',
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: AppFontWeights.bold,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomerDebtTile extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;

  const _CustomerDebtTile({required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateTimeHelper.formatDate(debt.transactionDate),
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              AppStatusBadge(status: debt.status),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          const Text(
            'Balance',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          AppMoneyText(
            amount: debt.balance,
            size: AppMoneySize.lg,
            color: debt.balance > 0 ? AppColors.textPrimary : AppColors.success,
          ),
        ],
      ),
    );
  }
}
