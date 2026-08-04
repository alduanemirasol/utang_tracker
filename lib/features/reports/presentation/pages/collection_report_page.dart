import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/error_view.dart';
import 'package:utang_tracker/core/widgets/loading_indicator.dart';
import 'package:utang_tracker/core/widgets/money_text.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_report.dart';
import 'package:utang_tracker/features/reports/presentation/providers/report_providers.dart';

class CollectionReportPage extends ConsumerStatefulWidget {
  const CollectionReportPage({super.key});

  @override
  ConsumerState<CollectionReportPage> createState() =>
      _CollectionReportPageState();
}

class _CollectionReportPageState extends ConsumerState<CollectionReportPage> {
  CollectionPeriod _period = CollectionPeriod.today;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(collectionReportProvider(_period));
    return Scaffold(
      appBar: AppBar(title: const Text('Collection Report')),
      body: async.when(
        loading: () => const LoadingIndicator(message: 'Crunching numbers'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(collectionReportProvider(_period)),
        ),
        data: (report) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(collectionReportProvider(_period));
            await ref.read(collectionReportProvider(_period).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              0,
              AppSpacing.pagePadding,
              AppSpacing.xxl,
            ),
            children: [
              Center(
                child: SegmentedButton<CollectionPeriod>(
                  segments: CollectionPeriod.values
                      .map(
                        (period) => ButtonSegment<CollectionPeriod>(
                          value: period,
                          label: Text(period.label),
                        ),
                      )
                      .toList(),
                  selected: {_period},
                  onSelectionChanged: (selection) {
                    setState(() => _period = selection.first);
                  },
                  showSelectedIcon: false,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _CollectedCard(report: report),
              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(title: 'By customer'),
              const SizedBox(height: AppSpacing.md),
              if (report.perCustomer.isEmpty)
                const _EmptyCard(message: 'Wala pay bayad niining panahona')
              else
                _CustomerBreakdown(items: report.perCustomer),
              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(title: 'Overdue'),
              const SizedBox(height: AppSpacing.md),
              if (report.overdueDebtCount == 0)
                const _EmptyCard(message: 'Wala nay overdue nga utang')
              else
                _OverdueBuckets(buckets: report.overdueBuckets),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectedCard extends StatelessWidget {
  const _CollectedCard({required this.report});

  final CollectionReport report;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: AppColors.primaryDark,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Collected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textOnPrimarySoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              MoneyText(
                report.collectedTotal,
                color: AppColors.accent,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${report.paymentCount} '
                '${report.paymentCount == 1 ? 'payment' : 'payments'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textOnPrimarySoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _DashedRule(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                report.period.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRule extends StatelessWidget {
  const _DashedRule();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const gapWidth = 6.0;
        final count = (constraints.maxWidth / (dashWidth + gapWidth)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dashWidth,
              height: 1,
              child: ColoredBox(color: AppColors.primaryDivider),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceRaised,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CustomerBreakdown extends StatelessWidget {
  const _CustomerBreakdown({required this.items});

  final List<CustomerCollection> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${items[i].paymentCount} '
                            '${items[i].paymentCount == 1 ? 'payment' : 'payments'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MoneyText(items[i].total, color: AppColors.primaryDark),
                  ],
                ),
              ),
              if (i != items.length - 1)
                const Divider(
                  height: AppSpacing.md,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverdueBuckets extends StatelessWidget {
  const _OverdueBuckets({required this.buckets});

  final List<OverdueBucket> buckets;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            for (var i = 0; i < buckets.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buckets[i].label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${buckets[i].debtCount} '
                            '${buckets[i].debtCount == 1 ? 'debt' : 'debts'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    MoneyText(buckets[i].total, color: AppColors.unpaid),
                  ],
                ),
              ),
              if (i != buckets.length - 1)
                const Divider(
                  height: AppSpacing.md,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                ),
            ],
          ],
        ),
      ),
    );
  }
}