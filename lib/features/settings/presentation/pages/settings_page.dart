import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_card.dart';
import 'package:utang_tracker/core/widgets/app_logo.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = info.version);
    } catch (_) {
      // Leave version null; UI falls back to a generic label.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.xxl,
        ),
        children: [
          AppCard(
            color: AppColors.primaryDark,
            borderColor: AppColors.primaryDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 60, borderRadius: 16),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppColors.textOnPrimary),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Perly Store’s pocket ledger',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRaised,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _appVersion == null ? 'v—' : 'v$_appVersion',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: AppColors.textOnPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Customer tabs, purchases, and payments stay organized on this device.',
                  style: TextStyle(
                    color: AppColors.textOnPrimarySoft,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Quick guide', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _GuideStep(
                  number: '01',
                  title: 'Add a customer',
                  detail: 'Save their name and contact details.',
                ),
                Divider(indent: 64),
                _GuideStep(
                  number: '02',
                  title: 'Record their utang',
                  detail: 'List each item, quantity, and price.',
                ),
                Divider(indent: 64),
                _GuideStep(
                  number: '03',
                  title: 'Log every payment',
                  detail: 'The remaining balance updates automatically.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: AppColors.primaryDark,
                fontSize: 12,
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
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
