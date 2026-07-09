import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/domain/debt.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_async_views.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_chip.dart';
import 'package:utang_tracker/core/presentation/app_empty_state.dart';
import 'package:utang_tracker/core/presentation/app_header.dart';
import 'package:utang_tracker/core/presentation/app_money_text.dart';
import 'package:utang_tracker/core/presentation/app_page_body.dart';
import 'package:utang_tracker/core/presentation/app_search_bar.dart';
import 'package:utang_tracker/core/presentation/app_status_badge.dart';
import 'package:utang_tracker/core/utils/app_responsive.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

enum _DebtSort { newest, oldest, highestBalance }

class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  DebtStatus? _selectedStatus;
  String _searchQuery = '';
  _DebtSort _sort = _DebtSort.newest;

  @override
  Widget build(BuildContext context) {
    final asyncDebts = ref.watch(debtListProvider);
    final asyncCustomers = ref.watch(customerListProvider);
    final responsive = AppResponsive.of(context);
    final hPad = responsive.horizontalPadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'debt_list_fab',
        onPressed: () => context.pushNamed('debtNew'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add debt'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppConstrainedWidth(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                hPad,
                hPad,
                AppSpacing.space5,
              ),
              child: AppHeader(
                label: 'Debts',
                trailing: PopupMenuButton<_DebtSort>(
                  tooltip: 'Sort',
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _DebtSort.newest,
                      child: Text('Newest'),
                    ),
                    PopupMenuItem(
                      value: _DebtSort.oldest,
                      child: Text('Oldest'),
                    ),
                    PopupMenuItem(
                      value: _DebtSort.highestBalance,
                      child: Text('Highest balance'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.space3),
                    child: Icon(
                      Icons.sort,
                      color: AppColors.primary,
                      size: AppFontSizes.iconMd,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AppConstrainedWidth(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: AppSearchBar(
                hintText: 'Search by customer name...',
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space5),
          AppConstrainedWidth(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                hPad,
                0,
                hPad,
                AppSpacing.space5,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppChip(
                      label: 'All',
                      isSelected: _selectedStatus == null,
                      onTap: () => _filterStatus(null),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    AppChip(
                      label: 'Unpaid',
                      isSelected: _selectedStatus == DebtStatus.unpaid,
                      onTap: () => _filterStatus(DebtStatus.unpaid),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    AppChip(
                      label: 'Partial',
                      isSelected: _selectedStatus == DebtStatus.partial,
                      onTap: () => _filterStatus(DebtStatus.partial),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    AppChip(
                      label: 'Paid',
                      isSelected: _selectedStatus == DebtStatus.paid,
                      onTap: () => _filterStatus(DebtStatus.paid),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: asyncDebts.when(
              loading: () => const AppLoadingView(),
              error: (e, _) => AppErrorView(
                message: 'Failed to load debts',
                onRetry: () => ref.read(debtListProvider.notifier).refresh(),
              ),
              data: (debts) {
                final customerNames = asyncCustomers.asData?.value ?? [];
                final nameMap = {
                  for (final c in customerNames) c.id: c.name,
                };

                var filtered = debts;
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  filtered = debts.where((d) {
                    final name = (nameMap[d.customerId] ?? '').toLowerCase();
                    return name.contains(q);
                  }).toList();
                }

                filtered = List<Debt>.from(filtered);
                switch (_sort) {
                  case _DebtSort.newest:
                    filtered.sort(
                      (a, b) => b.transactionDate.compareTo(a.transactionDate),
                    );
                  case _DebtSort.oldest:
                    filtered.sort(
                      (a, b) => a.transactionDate.compareTo(b.transactionDate),
                    );
                  case _DebtSort.highestBalance:
                    filtered.sort((a, b) => b.balance.compareTo(a.balance));
                }

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: _searchQuery.isNotEmpty
                        ? 'No matching debts'
                        : _selectedStatus != null
                            ? 'No debts with this status'
                            : 'No debts yet',
                    subtitle: _selectedStatus == null && _searchQuery.isEmpty
                        ? 'Add a debt to start tracking balances'
                        : null,
                    actionLabel:
                        _selectedStatus == null && _searchQuery.isEmpty
                            ? 'Add debt'
                            : null,
                    onAction: _selectedStatus == null && _searchQuery.isEmpty
                        ? () => context.pushNamed('debtNew')
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(debtListProvider.notifier).refresh(),
                  child: AppConstrainedWidth(
                    child: ListView.builder(
                      padding: responsive.listPadding(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final debt = filtered[index];
                        final customerName =
                            nameMap[debt.customerId] ?? 'Unknown';
                        return _DebtTile(
                          customerName: customerName,
                          totalAmount: debt.totalAmount,
                          balance: debt.balance,
                          status: debt.status,
                          date: debt.transactionDate,
                          onTap: () => context.pushNamed(
                            'debtDetail',
                            pathParameters: {'id': debt.id},
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _filterStatus(DebtStatus? status) {
    setState(() => _selectedStatus = status);
    ref.read(debtListProvider.notifier).filter(status: status);
  }
}

class _DebtTile extends StatelessWidget {
  final String customerName;
  final double totalAmount;
  final double balance;
  final DebtStatus status;
  final DateTime date;
  final VoidCallback onTap;

  const _DebtTile({
    required this.customerName,
    required this.totalAmount,
    required this.balance,
    required this.status,
    required this.date,
    required this.onTap,
  });

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
                  customerName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.lg,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              AppStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          const Text(
            'Remaining balance',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          AppMoneyText(
            amount: balance,
            size: AppMoneySize.xl,
            color: balance > 0 ? AppColors.textPrimary : AppColors.success,
          ),
          const SizedBox(height: AppSpacing.space5),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Total ${formatPeso(totalAmount)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                DateTimeHelper.formatDate(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
