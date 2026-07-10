import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/error/app_exception.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/utils/invalidate_helpers.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/confirmation_dialog.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/core/widgets/status_badge.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';

class CustomerDetailPage extends ConsumerWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerDetailProvider(customerId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: const LoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Customer')),
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Customer')),
            body: const Center(child: Text('Customer not found')),
          );
        }

        final customer = data.customer;

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/customers/$customerId/edit'),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirmed = await showConfirmationDialog(
                    context: context,
                    title: 'Delete customer?',
                    message:
                        'The customer will be hidden from lists. Related history stays in the database. Customers with debts cannot be deleted.',
                    confirmLabel: 'Delete',
                    isDestructive: true,
                  );
                  if (!confirmed || !context.mounted) return;
                  try {
                    await ref.read(deleteCustomerProvider)(customerId);
                    invalidateBusinessData(ref);
                    if (!context.mounted) return;
                    context.pop();
                  } on AppException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/debts/new?customerId=$customerId'),
            icon: const Icon(Icons.add),
            label: const Text('New debt'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerDetailProvider(customerId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                100,
              ),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding balance',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      MoneyText(
                        data.outstandingBalance,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        color: data.outstandingBalance.isZero
                            ? AppColors.paid
                            : AppColors.unpaid,
                      ),
                      if (customer.phone != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(customer.phone!),
                          ],
                        ),
                      ],
                      if (customer.notes != null &&
                          customer.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          customer.notes!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Debt history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.debts.isEmpty)
                  const Text(
                    'No debts yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ...data.debts.map(
                    (debt) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        onTap: () => context.push('/debts/${debt.id}'),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatters.formatDate(
                                      debt.transactionDate,
                                    ),
                                  ),
                                  MoneyText(debt.balance),
                                ],
                              ),
                            ),
                            StatusBadge(status: debt.status),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Payment history',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (data.payments.isEmpty)
                  const Text(
                    'No payments yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  )
                else
                  ...data.payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormatters.formatDate(
                                      payment.paymentDate,
                                    ),
                                  ),
                                  Text(
                                    payment.paymentMethod,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            MoneyText(
                              payment.amount,
                              color: AppColors.paid,
                            ),
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
}
