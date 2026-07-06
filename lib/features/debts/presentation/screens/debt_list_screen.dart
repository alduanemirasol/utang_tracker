import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/domain/debt_status.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_card.dart';
import 'package:utang_tracker/core/presentation/app_chip.dart';
import 'package:utang_tracker/core/presentation/app_header.dart';
import 'package:utang_tracker/core/utils/number_formatter.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';
import 'package:utang_tracker/features/debts/presentation/providers/debt_providers.dart';

class DebtListScreen extends ConsumerStatefulWidget {
  const DebtListScreen({super.key});

  @override
  ConsumerState<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends ConsumerState<DebtListScreen> {
  DebtStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final asyncDebts = ref.watch(debtListProvider);
    final asyncCustomers = ref.watch(customerListProvider);

    return Container(
      color: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.pushNamed('debtNew'),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: AppColors.onPrimary),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space7,
                  AppSpacing.space7,
                  AppSpacing.space7,
                  AppSpacing.space5,
                ),
                child: AppHeader(
                  label: 'Debts',
                  rightIcon: Icons.notifications_outlined,
                  onRightTap: () {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space7,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppChip(
                        label: 'All',
                        isSelected: _selectedStatus == null,
                        onTap: () {
                          setState(() => _selectedStatus = null);
                          ref
                              .read(debtListProvider.notifier)
                              .filter(status: null);
                        },
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      AppChip(
                        label: 'Unpaid',
                        isSelected: _selectedStatus == DebtStatus.unpaid,
                        onTap: () {
                          setState(
                              () => _selectedStatus = DebtStatus.unpaid);
                          ref
                              .read(debtListProvider.notifier)
                              .filter(status: DebtStatus.unpaid);
                        },
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      AppChip(
                        label: 'Partial',
                        isSelected: _selectedStatus == DebtStatus.partial,
                        onTap: () {
                          setState(
                              () => _selectedStatus = DebtStatus.partial);
                          ref
                              .read(debtListProvider.notifier)
                              .filter(status: DebtStatus.partial);
                        },
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      AppChip(
                        label: 'Paid',
                        isSelected: _selectedStatus == DebtStatus.paid,
                        onTap: () {
                          setState(() => _selectedStatus = DebtStatus.paid);
                          ref
                              .read(debtListProvider.notifier)
                              .filter(status: DebtStatus.paid);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space7),
              Expanded(
                child: asyncDebts.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space8),
                      child: Text(
                        'Failed to load debts',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  data: (debts) {
                    final customerNames =
                        asyncCustomers.asData?.value ?? [];
                    final nameMap = {
                      for (final c in customerNames) c.id: c.name,
                    };

                    if (debts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: AppFontSizes.iconL,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.space7),
                            Text(
                              _selectedStatus != null
                                  ? 'No debts with this status'
                                  : 'No debts yet',
                              style: const TextStyle(
                                fontSize: AppFontSizes.lg,
                                fontWeight: AppFontWeights.medium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_selectedStatus == null)
                              const Padding(
                                padding:
                                    EdgeInsets.only(top: AppSpacing.space3),
                                child: Text(
                                  'Tap + to create a debt',
                                  style: TextStyle(
                                    fontSize: AppFontSizes.sm,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(debtListProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space7,
                        ),
                        itemCount: debts.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.space3),
                        itemBuilder: (context, index) {
                          final debt = debts[index];
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    final statusColor = switch (status) {
      DebtStatus.unpaid => AppColors.error,
      DebtStatus.partial => AppColors.warning,
      DebtStatus.paid => AppColors.success,
    };
    final statusLabel = switch (status) {
      DebtStatus.unpaid => 'Unpaid',
      DebtStatus.partial => 'Partial',
      DebtStatus.paid => 'Paid',
    };

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: AppFontWeights.semibold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space3,
                  vertical: AppSpacing.space05,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.xs - 1,
                    fontWeight: AppFontWeights.semibold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: AppFontSizes.xs - 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      formatPeso(totalAmount),
                      style: const TextStyle(
                        fontSize: AppFontSizes.sm,
                        fontWeight: AppFontWeights.semibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: AppFontSizes.xs - 1,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      formatPeso(balance),
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        fontWeight: AppFontWeights.semibold,
                        color: balance > 0
                            ? AppColors.textPrimary
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            DateTimeHelper.formatDate(date),
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
