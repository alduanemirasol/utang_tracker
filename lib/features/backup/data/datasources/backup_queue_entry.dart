import 'dart:convert';

class BackupQueueEntry {
  const BackupQueueEntry({
    required this.type,
    required this.timestamp,
    this.retryCount = 0,
  });

  final String type;
  final DateTime timestamp;
  final int retryCount;

  Map<String, dynamic> toJson() => {
        'type': type,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'retryCount': retryCount,
      };

  factory BackupQueueEntry.fromJson(Map<String, dynamic> json) =>
      BackupQueueEntry(
        type: json['type'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int,
          isUtc: true,
        ),
        retryCount: (json['retryCount'] as int?) ?? 0,
      );

  BackupQueueEntry copyWith({int? retryCount}) => BackupQueueEntry(
        type: type,
        timestamp: timestamp,
        retryCount: retryCount ?? this.retryCount,
      );

  static String encodeList(List<BackupQueueEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<BackupQueueEntry> decodeList(String raw) {
    if (raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => BackupQueueEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
