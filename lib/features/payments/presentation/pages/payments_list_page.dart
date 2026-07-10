import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/empty_state.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/payments/presentation/providers/payment_providers.dart';

class PaymentsListPage extends ConsumerWidget {
  const PaymentsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(paymentsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payments/new'),
        tooltip: 'Record payment',
        icon: const Icon(Icons.add),
        label: const Text('Record payment'),
      ),
      body: async.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(paymentsListProvider),
        ),
        data: (payments) {
          if (payments.isEmpty) {
            return EmptyState(
              icon: Icons.payments_outlined,
              title: 'No payments yet',
              message: 'Record a payment when a customer pays their utang.',
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(paymentsListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                88,
              ),
              itemCount: payments.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final payment = payments[index];
                return AppCard(
                  onTap: () => context.push('/debts/${payment.debtId}'),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.customerName ?? 'Customer',
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${DateFormatters.formatDate(payment.paymentDate)} · ${payment.paymentMethod}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      MoneyText(payment.amount, color: AppColors.paid),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
