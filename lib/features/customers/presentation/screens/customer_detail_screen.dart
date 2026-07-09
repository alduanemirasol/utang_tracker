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
import 'package:utang_tracker/core/presentation/app_info_row.dart';
import 'package:utang_tracker/core/presentation/app_inline_empty.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/core/presentation/app_section_header.dart';
import 'package:utang_tracker/core/presentation/app_page_body.dart';
import 'package:utang_tracker/core/presentation/app_status_badge.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';
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
          PopupMenuButton<_CustomerDetailAction>(
            tooltip: 'More options',
            onSelected: (action) {
              switch (action) {
                case _CustomerDetailAction.edit:
                  context.pushNamed(
                    'customerEdit',
                    pathParameters: {'id': customerId},
                  );
                case _CustomerDetailAction.delete:
                  _confirmDelete(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _CustomerDetailAction.edit,
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: _CustomerDetailAction.delete,
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
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

          return AppConstrainedWidth(
            child: ListView(
              padding: AppResponsive.of(context).pagePadding(),
              children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSizes.x2l,
                        fontWeight: AppFontWeights.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (customer.phone case final phone?) ...[
                      const SizedBox(height: AppSpacing.space5),
                      AppInfoRow(icon: Icons.phone_outlined, label: phone),
                    ],
                    if (customer.notes case final notes?) ...[
                      const SizedBox(height: AppSpacing.space5),
                      AppInfoRow(icon: Icons.notes_outlined, label: notes),
                    ],
                    const SizedBox(height: AppSpacing.space5),
                    AppInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label:
                          'Customer since ${DateTimeHelper.formatDate(customer.createdAt)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              _StatsRow(
                totalDebts: summary.totalDebts,
                totalBalance: summary.totalBalance,
                totalPaid: summary.totalPaid,
              ),
              const SizedBox(height: AppSpacing.space5),
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
                const AppInlineEmpty(
                  icon: Icons.receipt_long_outlined,
                  title: 'No debts for this customer',
                  subtitle: 'Use Add debt above to start tracking',
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
            ),
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

enum _CustomerDetailAction { edit, delete }

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
    final responsive = AppResponsive.of(context);
    final stack = responsive.isCompact || responsive.isLargeText;

    final debts = _StatCard(
      label: 'Debts',
      value: '$totalDebts',
      color: AppColors.primary,
    );
    final balance = _StatCard(
      label: 'Balance',
      amount: totalBalance,
      color: AppColors.warning,
    );
    final paid = _StatCard(
      label: 'Paid',
      amount: totalPaid,
      color: AppColors.success,
    );

    if (stack) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: debts),
              const SizedBox(width: AppSpacing.space5),
              Expanded(child: balance),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          paid,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: debts),
        const SizedBox(width: AppSpacing.space5),
        Expanded(child: balance),
        const SizedBox(width: AppSpacing.space5),
        Expanded(child: paid),
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
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          if (amount != null)
            AppMoneyText(
              amount: amount!,
              size: AppMoneySize.sm,
              color: AppColors.textPrimary,
              textAlign: TextAlign.center,
            )
          else
            Text(
              value ?? '',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
