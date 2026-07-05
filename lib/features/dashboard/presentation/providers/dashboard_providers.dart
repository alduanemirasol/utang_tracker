import 'package:riverpod/riverpod.dart';
import 'package:utang_tracker/core/presentation/providers/database_provider.dart';
import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_repository.dart';
import 'package:utang_tracker/features/dashboard/infrastructure/dashboard_data_source.dart';
import 'package:utang_tracker/features/dashboard/infrastructure/dashboard_repository_impl.dart';
import 'package:utang_tracker/features/dashboard/application/get_dashboard_use_case.dart';


final dashboardDataSourceProvider = Provider<DashboardDataSource>((ref) {
  return DashboardDataSource(ref.read(databaseProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.read(dashboardDataSourceProvider));
});


final getDashboardUseCaseProvider = Provider<GetDashboardUseCase>((ref) {
  return GetDashboardUseCase(ref.read(dashboardRepositoryProvider));
});


final dashboardProvider = FutureProvider<DashboardSummary>((ref) async {
  final result = await ref.read(getDashboardUseCaseProvider).execute();
  return switch (result) {
    Success(data: final summary) => summary,
    Error(failure: final f) => throw f,
  };
});
