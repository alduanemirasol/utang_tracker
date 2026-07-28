enum BackupFailureKind {
  invalidFile,
  wrongApplication,
  unsupportedSchema,
  integrity,
  restore,
}

class BackupException implements Exception {
  const BackupException(this.kind, this.message, [this.cause]);

  final BackupFailureKind kind;
  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
