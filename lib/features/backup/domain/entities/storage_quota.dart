import 'package:equatable/equatable.dart';

class StorageQuota extends Equatable {
  const StorageQuota({
    required this.usedBytes,
    required this.totalBytes,
    required this.availableBytes,
  });

  final int usedBytes;
  final int? totalBytes;
  final int? availableBytes;

  Map<String, dynamic> toJson() => {
        'usedBytes': usedBytes,
        'totalBytes': totalBytes,
        'availableBytes': availableBytes,
      };

  factory StorageQuota.fromJson(Map<String, dynamic> json) => StorageQuota(
        usedBytes: json['usedBytes'] as int,
        totalBytes: json['totalBytes'] as int?,
        availableBytes: json['availableBytes'] as int?,
      );

  @override
  List<Object?> get props => [usedBytes, totalBytes, availableBytes];
}
