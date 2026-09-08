import 'package:utang_tracker/features/backup/domain/entities/backup_queue_entry.dart';
import 'package:utang_tracker/features/backup/domain/repositories/backup_queue_repository.dart';

class HandleBackupQueue {
  const HandleBackupQueue(this._queue);

  final BackupQueueRepository _queue;

  Future<List<BackupQueueEntry>> getQueue() => _queue.getQueue();

  Future<int> getQueueCount() => _queue.getQueueCount();

  Future<bool> hasQueued() => _queue.hasQueued();

  Future<void> enqueue(String type) => _queue.enqueue(type);
}
