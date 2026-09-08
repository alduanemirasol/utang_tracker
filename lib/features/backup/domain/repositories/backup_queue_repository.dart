import 'package:utang_tracker/features/backup/domain/entities/backup_queue_entry.dart';

abstract class BackupQueueRepository {
  Future<List<BackupQueueEntry>> getQueue();
  Future<int> getQueueCount();
  Future<bool> hasQueued();
  Future<void> enqueue(String type);
  Future<BackupQueueEntry?> peek();
  Future<void> dequeue();
}
