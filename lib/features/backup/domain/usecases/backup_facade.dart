import 'package:utang_tracker/features/backup/domain/entities/backup_meta.dart';
import 'package:utang_tracker/features/backup/domain/entities/storage_quota.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_repository.dart';

class BackupFacade {
  const BackupFacade(this._repository);

  final BackupRepository _repository;

  Future<BackupMeta> createBackup() => _repository.createBackup();

  Future<List<BackupMeta>> browseBackups() => _repository.browseBackups();

  Future<void> restoreBackup(
    String backupId, {
    bool confirmed = false,
    void Function(double)? onProgress,
  }) =>
      _repository.restoreBackup(backupId, confirmed: confirmed, onProgress: onProgress);

  Future<StorageQuota> getQuota() => _repository.getQuota();

  Future<bool> isLowStorage() => _repository.isLowStorage();
}
