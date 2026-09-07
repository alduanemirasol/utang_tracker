import 'package:utang_tracker/features/backup/domain/entities/backup_history_entry.dart';

abstract class BackupHistoryRepository {
  Future<List<BackupHistoryEntry>> getEntries();
  Future<void> addEntry(BackupHistoryEntry entry);
  Future<void> clear();
}
