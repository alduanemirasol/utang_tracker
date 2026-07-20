import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:utang_tracker/core/constants/app_constants.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
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
  String? _version;
  DateTime? _lastChecked;
  Map<String, dynamic>? _releaseNotes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(updateRepositoryProvider);
    final version = await repo.getCurrentVersion();
    final lastChecked = await repo.loadLastCheckTime();
    final jsonStr = await repo.loadReleaseNotes().catchError((_) => '{}');
    final data = jsonDecode(jsonStr);
    if (mounted) {
      setState(() {
        _version = version;
        _lastChecked = lastChecked;
        _releaseNotes = data is Map ? Map<String, dynamic>.from(data) : null;
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
          _AppHeader(version: _version),
          const SizedBox(height: AppSpacing.xxl),
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
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel("What's new"),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(
            children: [
              if (_releaseNotes != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final note
                          in (_releaseNotes!['notes'] as List).cast<String>())
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•  ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            Expanded(
                              child: Text(
                                note,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.6,
                                    ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel('Credits'),
          const SizedBox(height: AppSpacing.sm),
          _InfoCard(
            children: [
              _InfoRow(label: 'Developer', value: 'Al Duane Mirasol'),
              const Divider(height: 1),
              const _SocialLinkRow(),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.version});

  final String? version;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const AppLogo(size: 72, borderRadius: 18),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          version != null ? 'v$version' : '—',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SocialLinkRow extends StatelessWidget {
  const _SocialLinkRow();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(AppConstants.facebookUrl)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const Icon(Icons.facebook, size: 22, color: AppColors.primaryDark),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Facebook',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
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
