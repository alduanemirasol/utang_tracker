import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/utils/date_formatters.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_search_bar.dart';
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
    final filters = ref.watch(paymentFiltersProvider);
    final optionsAsync = ref.watch(paymentFilterOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bayad')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payments/new'),
        tooltip: 'Record bayad',
        icon: const Icon(Icons.add),
        label: const Text('Record bayad'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          optionsAsync.maybeWhen(
            data: (options) {
              if (!options.hasPayments && !filters.hasActiveFilters) {
                return const SizedBox.shrink();
              }

              return _PaymentFiltersBar(
                filters: filters,
                paymentMethods: options.paymentMethods,
                onSearchChanged: (value) {
                  ref
                      .read(paymentFiltersProvider.notifier)
                      .setSearchQuery(value);
                },
                onMethodSelected: (method) {
                  ref
                      .read(paymentFiltersProvider.notifier)
                      .setPaymentMethod(method);
                },
                onDateRangeSelected: (range) {
                  ref
                      .read(paymentFiltersProvider.notifier)
                      .setDateRange(
                        startDate: range?.start,
                        endDate: range?.end,
                      );
                },
                onClear: () =>
                    ref.read(paymentFiltersProvider.notifier).clear(),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () {
                  ref.invalidate(paymentFilterOptionsProvider);
                  ref.invalidate(paymentsListProvider);
                },
              ),
              data: (payments) {
                if (payments.isEmpty) {
                  return EmptyState(
                    icon: filters.hasActiveFilters
                        ? Icons.filter_alt_off_outlined
                        : Icons.payments_outlined,
                    title: filters.hasActiveFilters
                        ? 'Walay bayad'
                        : 'Wala pay nibayad',
                    message: filters.hasActiveFilters
                        ? 'I-adjust ang filter sa bayad'
                        : 'Tap "+ Record bayad" para marecord ang bayad.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(paymentFilterOptionsProvider);
                    await ref.read(paymentsListProvider.notifier).refresh();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.xs,
                      AppSpacing.pagePadding,
                      104,
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
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.paidBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 20,
                                color: AppColors.paid,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          payment.customerName ?? 'Customer',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      MoneyText(
                                        payment.amount,
                                        color: AppColors.paid,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${DateFormatters.formatDate(payment.paymentDate)} - ${payment.paymentMethod}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        DateFormatters.formatTime(
                                          payment.paymentDate,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

class _PaymentFiltersBar extends StatelessWidget {
  const _PaymentFiltersBar({
    required this.filters,
    required this.paymentMethods,
    required this.onSearchChanged,
    required this.onMethodSelected,
    required this.onDateRangeSelected,
    required this.onClear,
  });

  final PaymentFilters filters;
  final List<String> paymentMethods;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onMethodSelected;
  final ValueChanged<DateTimeRange?> onDateRangeSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _dateFilterLabel(filters);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        0,
        AppSpacing.pagePadding,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchBar(
            key: const ValueKey('payment-search'),
            hintText: 'Search by customer',
            initialValue: filters.searchQuery,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: filters.paymentMethod == null,
                        onSelected: () => onMethodSelected(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...paymentMethods.map(
                        (method) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: _FilterChip(
                            label: method,
                            selected: filters.paymentMethod == method,
                            onSelected: () => onMethodSelected(method),
                          ),
                        ),
                      ),
                      _DateFilterChip(
                        label: dateLabel,
                        selected:
                            filters.startDate != null ||
                            filters.endDate != null,
                        onSelected: () => _pickDateRange(context),
                      ),
                    ],
                  ),
                ),
              ),
              if (filters.hasActiveFilters) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  tooltip: 'Clear filters',
                  onPressed: onClear,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = filters.startDate ?? now;
    final initialEnd = filters.endDate ?? initialStart;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (range != null) {
      onDateRangeSelected(range);
    }
  }

  String _dateFilterLabel(PaymentFilters filters) {
    if (filters.startDate == null || filters.endDate == null) {
      return 'Date';
    }

    if (DateFormatters.isSameLocalDay(filters.startDate!, filters.endDate!)) {
      return DateFormatters.formatDate(filters.startDate!);
    }

    return '${DateFormatters.formatDate(filters.startDate!)} - ${DateFormatters.formatDate(filters.endDate!)}';
  }
}

class _DateFilterChip extends StatelessWidget {
  const _DateFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        Icons.calendar_month_outlined,
        size: 18,
        color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
      label: Text(label),
      onPressed: onSelected,
      backgroundColor: selected ? AppColors.primaryDark : AppColors.surfaceCard,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: selected ? AppColors.primaryDark : AppColors.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      selectedColor: AppColors.primaryDark,
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
      ),
      backgroundColor: AppColors.surfaceCard,
      side: BorderSide(
        color: selected ? AppColors.primaryDark : AppColors.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
