import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utang_tracker/core/providers/core_providers.dart';
import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/domain/usecases/get_dashboard_summary.dart';

final getDashboardSummaryProvider = Provider((ref) {
  return GetDashboardSummary(ref.watch(dashboardRepositoryProvider));
});

final dashboardSummaryProvider =
    AsyncNotifierProvider<DashboardSummaryNotifier, DashboardSummary>(
  DashboardSummaryNotifier.new,
);

class DashboardSummaryNotifier extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() {
    return ref.watch(getDashboardSummaryProvider)();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getDashboardSummaryProvider)());
  }
}
