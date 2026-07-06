import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/core/constants/app_colors.dart';
import 'package:utang_tracker/core/constants/app_font_sizes.dart';
import 'package:utang_tracker/core/constants/app_font_weights.dart';
import 'package:utang_tracker/core/constants/app_radius.dart';
import 'package:utang_tracker/core/constants/app_spacing.dart';
import 'package:utang_tracker/core/helpers/date_time_helper.dart';
import 'package:utang_tracker/core/presentation/app_header.dart';
import 'package:utang_tracker/core/presentation/app_search_bar.dart';
import 'package:utang_tracker/features/customers/presentation/providers/customer_providers.dart';

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

    return Container(
      color: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.pushNamed('customerNew'),
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
                  label: 'Customers',
                  rightIcon: Icons.notifications_outlined,
                  onRightTap: () {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space7,
                ),
                child: AppSearchBar(
                  hintText: 'Search customers...',
                  onChanged: (value) {
                    _query = value;
                    ref
                        .read(customerListProvider.notifier)
                        .search(value);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.space7),
              Expanded(
                child: asyncCustomers.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space8),
                      child: Text(
                        'Failed to load customers',
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  data: (customers) {
                    if (customers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: AppFontSizes.iconL,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppSpacing.space7),
                            Text(
                              _query.isNotEmpty
                                  ? 'No customers found'
                                  : 'No customers yet',
                              style: const TextStyle(
                                fontSize: AppFontSizes.lg,
                                fontWeight: AppFontWeights.medium,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_query.isEmpty) ...[
                              const SizedBox(height: AppSpacing.space3),
                              Text(
                                'Tap + to add your first customer',
                                style: const TextStyle(
                                  fontSize: AppFontSizes.sm,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space7,
                      ),
                      itemCount: customers.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.space3),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return _CustomerTile(
                          name: customer.name,
                          subtitle: customer.phone ?? customer.notes,
                          date: customer.createdAt,
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
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final String name;
  final String? subtitle;
  final DateTime date;
  final VoidCallback onTap;

  const _CustomerTile({
    required this.name,
    this.subtitle,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space7),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                        fontSize: AppFontSizes.md,
                        fontWeight: AppFontWeights.semibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space05),
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
                    const SizedBox(height: AppSpacing.space05),
                    Text(
                      DateTimeHelper.formatDate(date),
                      style: const TextStyle(
                        fontSize: AppFontSizes.xs - 1,
                        color: AppColors.textSecondary,
                      ),
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
