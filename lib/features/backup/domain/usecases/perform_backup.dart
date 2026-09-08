import 'package:utang_tracker/features/backup/domain/entities/backup_meta.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_repository.dart';

class PerformBackup {
  const PerformBackup(this._repository);

  final BackupRepository _repository;

  Future<BackupMeta> call() => _repository.createBackup();
}
