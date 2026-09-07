import 'package:utang_tracker/features/backup/domain/entities/backup_meta.dart';
import 'package:utang_tracker/features/backup/domain/entities/storage_quota.dart';

abstract class BackupRepository {
  Future<List<BackupMeta>> listBackups();
  Future<List<BackupMeta>> browseBackups();
  Future<BackupMeta> createBackup();
  Future<void> restoreBackup(String id, {bool confirmed = false, void Function(double)? onProgress});
  Future<void> deleteBackup(String id);
  Future<StorageQuota> getQuota();
  Future<bool> isLowStorage();
}
