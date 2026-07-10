import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_search_bar.dart';
import 'package:utang_tracker/core/widgets/empty_state.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';

class CustomersListPage extends ConsumerWidget {
  const CustomersListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/new'),
        tooltip: 'Add customer',
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: AppSearchBar(
              hintText: 'Search by name',
              onChanged: (value) {
                ref.read(customerSearchQueryProvider.notifier).setQuery(value);
              },
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(customersListProvider),
              ),
              data: (customers) {
                if (customers.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: 'No customers yet',
                    message: 'Add your first customer to start tracking utang.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(customersListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.sm,
                      AppSpacing.pagePadding,
                      88,
                    ),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return AppCard(
                        onTap: () => context.push('/customers/${customer.id}'),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primary,
                              child: Text(
                                customer.name.isNotEmpty
                                    ? customer.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (customer.phone != null &&
                                      customer.phone!.isNotEmpty)
                                    Text(
                                      customer.phone!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
