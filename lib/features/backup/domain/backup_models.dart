import 'dart:io';

class PreparedRestore {
  const PreparedRestore({
    required this.file,
    required this.originalSchemaVersion,
    required this.schemaVersion,
  });

  final File file;
  final int originalSchemaVersion;
  final int schemaVersion;

  bool get wasMigrated => originalSchemaVersion != schemaVersion;
}

class RestoreResult {
  const RestoreResult({
    required this.rollbackBackup,
    required this.wasMigrated,
  });

  final File rollbackBackup;
  final bool wasMigrated;
}
