class BackupException implements Exception {
  const BackupException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
