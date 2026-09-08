import 'package:utang_tracker/features/backup/data/services/backup_queue_service.dart';
import 'package:utang_tracker/features/backup/domain/entities/backup_queue_entry.dart' as domain;
import 'package:utang_tracker/features/backup/domain/repositories/backup_queue_repository.dart';

class BackupQueueRepositoryImpl implements BackupQueueRepository {
  BackupQueueRepositoryImpl({BackupQueueService? queueService}) : _queueService = queueService ?? BackupQueueService();

  final BackupQueueService _queueService;

  domain.BackupQueueEntry _toDomain(dynamic entry) {
    return domain.BackupQueueEntry(
      type: entry.type as String,
      timestamp: entry.timestamp as DateTime,
      retryCount: entry.retryCount as int,
    );
  }

  @override
  Future<List<domain.BackupQueueEntry>> getQueue() async {
    final queue = await _queueService.loadQueue();
    return queue.map(_toDomain).toList();
  }

  @override
  Future<int> getQueueCount() async => _queueService.queuedCount();

  @override
  Future<bool> hasQueued() async => _queueService.hasQueued();

  @override
  Future<void> enqueue(String type) async => _queueService.enqueue(type);

  @override
  Future<domain.BackupQueueEntry?> peek() async {
    final entry = await _queueService.peek();
    if (entry == null) return null;
    return _toDomain(entry);
  }

  @override
  Future<void> dequeue() async => _queueService.dequeue();
}
