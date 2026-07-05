import 'package:utang_tracker/core/errors/result.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_repository.dart';
import 'package:utang_tracker/features/dashboard/domain/dashboard_summary.dart';

class GetDashboardUseCase {
  final DashboardRepository _repository;

  GetDashboardUseCase(this._repository);

  Future<Result<DashboardSummary>> execute() {
    return _repository.getSummary();
  }
}
