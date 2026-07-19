import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/core/widgets/app_logo.dart';
import 'package:utang_tracker/features/updater/presentation/providers/update_providers.dart';
import 'package:utang_tracker/features/updater/presentation/widgets/update_bottom_sheet.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  PackageInfo? _info;
  DateTime? _lastChecked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    final repo = ref.read(updateRepositoryProvider);
    final lastChecked = await repo.loadLastCheckTime();
    if (mounted) {
      setState(() {
        _info = info;
        _lastChecked = lastChecked;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    await ref.read(updateNotifierProvider.notifier).checkForUpdates();
    if (!mounted) return;
    await showUpdateBottomSheet(context);
  }

  String _formatLastChecked(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final isChecking = updateState is UpdateChecking;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.lg,
        ),
        children: [
          _AppHeader(info: _info),
          const SizedBox(height: AppSpacing.xxl),
          _SectionLabel('App info'),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(
            children: [
              _InfoRow(
                label: 'Version',
                value: _info != null
                    ? 'v${_info!.version} (${_info!.buildNumber})'
                    : '—',
              ),
              const Divider(height: 1),
              _InfoRow(label: 'App name', value: AppConstants.appName),
              const Divider(height: 1),
              _InfoRow(
                label: 'Repository',
                value:
                    '${AppConstants.githubOwner}/${AppConstants.githubRepo}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel('Updates'),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(
            children: [
              _InfoRow(
                label: 'Last checked',
                value: _formatLastChecked(_lastChecked),
              ),
              const Divider(height: 1),
              _CheckForUpdatesRow(
                isChecking: isChecking,
                onTap: isChecking ? null : _checkForUpdates,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.info});

  final PackageInfo? info;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        const AppLogo(size: 72),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (info != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'v${info!.version}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckForUpdatesRow extends StatelessWidget {
  const _CheckForUpdatesRow({required this.isChecking, required this.onTap});

  final bool isChecking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Check for updates',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isChecking)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryDark,
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryDark,
              ),
          ],
        ),
      ),
    );
  }
}
