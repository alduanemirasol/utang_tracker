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
import 'package:utang_tracker/core/widgets/status_badge.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_sort_order.dart';
import 'package:utang_tracker/features/debts/domain/entities/debt_status.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class DebtsListPage extends ConsumerWidget {
  const DebtsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(debtStatusFilterProvider);
    final sort = ref.watch(debtSortOrderProvider);
    final debtsAsync = ref.watch(debtsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Debts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/debts/new'),
        tooltip: 'New debt',
        icon: const Icon(Icons.add),
        label: const Text('New debt'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: filter == null,
                          onSelected: () => ref
                              .read(debtStatusFilterProvider.notifier)
                              .setFilter(null),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ...DebtStatus.values.map(
                          (s) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: _FilterChip(
                              label: s.label,
                              selected: filter == s,
                              onSelected: () => ref
                                  .read(debtStatusFilterProvider.notifier)
                                  .setFilter(s),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<DebtSortOrder>(
                  tooltip: 'Sort debts',
                  initialValue: sort,
                  onSelected: (order) {
                    ref.read(debtSortOrderProvider.notifier).setSort(order);
                  },
                  itemBuilder: (context) {
                    return DebtSortOrder.values.map((order) {
                      return PopupMenuItem<DebtSortOrder>(
                        value: order,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: sort == order
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                            Expanded(child: Text(order.label)),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      Icons.sort,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: debtsAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(debtsListProvider),
              ),
              data: (debts) {
                if (debts.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No debts found',
                    message: filter == null
                        ? 'Record a debt when a customer buys on utang.'
                        : 'No ${filter.label.toLowerCase()} debts.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(debtsListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.sm,
                      AppSpacing.pagePadding,
                      88,
                    ),
                    itemCount: debts.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final debt = debts[index];
                      return AppCard(
                        onTap: () => context.push('/debts/${debt.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    debt.customerName ?? 'Customer',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusBadge(status: debt.status),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    DateFormatters.formatDate(
                                      debt.transactionDate,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Balance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    MoneyText(debt.balance),
                                  ],
                                ),
                              ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surfaceCard,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.outline,
      ),
    );
  }
}
