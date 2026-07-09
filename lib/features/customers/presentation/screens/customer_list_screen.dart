import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_empty_state.dart';
import 'package:utang_tracker/core/presentation/app_header.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/core/presentation/app_search_bar.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncCustomers = ref.watch(customerListProvider);
    final asyncDebts = ref.watch(allDebtsProvider);

    final balances = <String, double>{};
    final debts = asyncDebts.asData?.value;
    if (debts != null) {
      for (final debt in debts) {
        balances[debt.customerId] =
            (balances[debt.customerId] ?? 0) + debt.balance;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customer_list_fab',
        onPressed: () => context.pushNamed('customerNew'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add customer'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.space7,
              AppSpacing.space7,
              AppSpacing.space7,
              AppSpacing.space5,
            ),
            child: AppHeader(label: 'Customers'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space7),
            child: AppSearchBar(
              hintText: 'Search customers...',
              onChanged: (value) {
                _query = value;
                ref.read(customerListProvider.notifier).search(value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.space7),
          Expanded(
            child: asyncCustomers.when(
              loading: () => const AppLoadingView(),
              error: (e, _) => AppErrorView(
                message: 'Failed to load customers',
                onRetry: () =>
                    ref.read(customerListProvider.notifier).refresh(),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.people_outline,
                    message: _query.isNotEmpty
                        ? 'No customers found'
                        : 'No customers yet',
                    subtitle: _query.isEmpty
                        ? 'Add a customer to start tracking debts'
                        : null,
                    actionLabel: _query.isEmpty ? 'Add customer' : null,
                    onAction: _query.isEmpty
                        ? () => context.pushNamed('customerNew')
                        : null,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space7,
                    0,
                    AppSpacing.space7,
                    AppSpacing.space80,
                  ),
                  itemCount: customers.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.space3),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _CustomerTile(
                      name: customer.name,
                      subtitle: customer.phone ?? customer.notes,
                      balance: balances[customer.id] ?? 0,
                      onTap: () => context.pushNamed(
                        'customerDetail',
                        pathParameters: {'id': customer.id},
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final double balance;
  final VoidCallback onTap;

  const _CustomerTile({
    required this.name,
    this.subtitle,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space7),
          child: Row(
            children: [
              Container(
                width: AppSpacing.space48,
                height: AppSpacing.space48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xsm),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: AppFontSizes.iconSm,
                ),
              ),
              const SizedBox(width: AppSpacing.space5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: AppFontSizes.lg,
                        fontWeight: AppFontWeights.semibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space3),
                    Row(
                      children: [
                        const Text(
                          'Balance ',
                          style: TextStyle(
                            fontSize: AppFontSizes.sm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppMoneyText(
                          amount: balance,
                          size: AppMoneySize.sm,
                          color: balance > 0
                              ? AppColors.textPrimary
                              : AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: AppFontSizes.iconSm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
