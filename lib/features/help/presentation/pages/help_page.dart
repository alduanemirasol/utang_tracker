import 'package:flutter/material.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.lg,
        ),
        children: const [
          _SectionLabel('Getting started'),
          SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpBullet(
                  'Add a customer: open the Customers tab, then tap + New customer.',
                ),
                _HelpBullet(
                  'Record a utang: tap + New utang, pick the customer, add items, then Save.',
                ),
                _HelpBullet(
                  'Record a bayad: open the utang, then tap Record bayad.',
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          _SectionLabel('Tips'),
          SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpBullet(
                  'A utang can only be edited while no payment has been recorded.',
                ),
                _HelpBullet(
                  'Deleting a customer only hides them; paid history stays visible.',
                ),
                _HelpBullet('Back up regularly: Settings > Backup & Restore.'),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _HelpBullet extends StatelessWidget {
  const _HelpBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      height: 1.5,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: style),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
