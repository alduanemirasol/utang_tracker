import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:utang_tracker/app/coordination.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/core/theme/app_colors.dart';
import 'package:utang_tracker/core/theme/app_spacing.dart';
import 'package:utang_tracker/features/notifications/presentation/providers/notification_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersEnabled = ref.watch(reminderEnabledProvider).value ?? true;

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
          _ReminderToggle(enabled: remindersEnabled),
          const SizedBox(height: AppSpacing.sm),
          _MenuItem(
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            subtitle: 'Export or restore your data',
            onTap: () => context.push('/backup-restore'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MenuItem(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'App version and updates',
            onTap: () => context.push('/about'),
          ),
        ],
      ),
    );
  }
}

class _ReminderToggle extends ConsumerWidget {
  const _ReminderToggle({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile(
        value: enabled,
        onChanged: (value) => _onChanged(ref, value),
        secondary: const Icon(
          Icons.notifications_active_outlined,
          color: AppColors.primaryDark,
          size: 28,
        ),
        title: Text('Reminders', style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(
          'Receive a 09:00 notice for due and overdue utang',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _onChanged(WidgetRef ref, bool value) async {
    await ref.read(reminderEnabledProvider.notifier).setEnabled(value);
    if (value) {
      final scheduler = ref.read(reminderSchedulerProvider);
      await scheduler.requestNotificationsPermission();
      syncDebtReminders(ref);
    } else {
      await ref.read(reminderSchedulerProvider).cancelAll();
    }
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryDark, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}