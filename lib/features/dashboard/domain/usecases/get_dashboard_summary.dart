import 'package:utang_tracker/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:utang_tracker/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardSummary {
  const GetDashboardSummary(this._repository);
  final DashboardRepository _repository;
  Future<DashboardSummary> call() => _repository.getSummary();
}
