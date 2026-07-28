import 'dart:io';

import 'package:flutter/services.dart';

class BackupFileGateway {
  const BackupFileGateway();

  static const _channel = MethodChannel(
    'com.example.utang_tracker/backup_files',
  );

  Future<bool> save(File source, String fileName) async {
    final saved = await _channel.invokeMethod<bool>('saveBackup', {
      'sourcePath': source.path,
      'fileName': fileName,
    });
    return saved ?? false;
  }

  Future<File?> pick() async {
    final path = await _channel.invokeMethod<String>('pickBackup');
    return path == null ? null : File(path);
  }
}
