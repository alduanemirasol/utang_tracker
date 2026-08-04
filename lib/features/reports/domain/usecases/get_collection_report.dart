import 'package:utang_tracker/features/reports/domain/entities/collection_period.dart';
import 'package:utang_tracker/features/reports/domain/entities/collection_report.dart';
import 'package:utang_tracker/features/reports/domain/repositories/report_repository.dart';

class GetCollectionReport {
  const GetCollectionReport(this._repository);

  final ReportRepository _repository;

  Future<CollectionReport> call(CollectionPeriod period, {DateTime? now}) {
    return _repository.getCollectionReport(
      period: period,
      now: now ?? DateTime.now(),
    );
  }
}