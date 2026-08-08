import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/app/coordination.dart';
import 'package:utang_tracker/features/notifications/presentation/providers/notification_providers.dart';

class ReminderBootstrap extends ConsumerStatefulWidget {
  const ReminderBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReminderBootstrap> createState() => _ReminderBootstrapState();
}

class _ReminderBootstrapState extends ConsumerState<ReminderBootstrap> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;
    try {
      final enabled = await ref.read(reminderEnabledProvider.future);
      if (enabled) {
        syncDebtReminders(ref);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}