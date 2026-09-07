import 'package:utang_tracker/features/backup/data/datasources/backup_local_datasource.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_history_entry.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_history_repository.dart';

class BackupHistoryRepositoryImpl implements BackupHistoryRepository {
  BackupHistoryRepositoryImpl(this._datasource);

  final BackupLocalDatasource _datasource;

  @override
  Future<List<BackupHistoryEntry>> getEntries() => _datasource.loadHistory();

  @override
  Future<void> addEntry(BackupHistoryEntry entry) => _datasource.appendHistory(entry);

  @override
  Future<void> clear() => _datasource.clearHistory();
}
