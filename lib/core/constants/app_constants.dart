class AppConstants {
  AppConstants._();

  static const String appName = 'Utang Tracker';
  static const String logoAsset = 'assets/images/new-logo.png';

  static const List<String> paymentMethods = [
    'Cash',
    'GCash',
    'Bank Transfer',
    'Other',
  ];

  static const int recentItemsLimit = 5;

  static const String githubOwner = 'alduanemirasol';
  static const String githubRepo = 'utang_tracker';
  static const String githubApiBaseUrl = 'https://api.github.com';

  static const String apkAssetPrefix = 'utang-tracker';

  static const String universalAbiName = 'universal';

  static const String updaterChannel = 'com.example.utang_tracker/updater';

  // Google Drive backup constants.
  static const List<String> driveScopes = [
    'https://www.googleapis.com/auth/drive.file',
  ];
  static const String driveBackupMimeType = 'application/x-sqlite3';
  static const String driveQuery =
      "mimeType = 'application/x-sqlite3' and trashed = false";
}
