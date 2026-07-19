/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Utang Tracker';
  static const String logoAsset = 'assets/images/utang_tracker_logo_v2.png';
  static const String currencySymbol = '₱';

  static const List<String> paymentMethods = [
    'Cash',
    'GCash',
    'Bank Transfer',
    'Other',
  ];

  static const int recentItemsLimit = 5;

  // ── GitHub Releases updater ──────────────────────────────────────────────
  static const String githubOwner = 'alduanemirasol';
  static const String githubRepo = 'utang_tracker';
  static const String githubApiBaseUrl = 'https://api.github.com';

  /// Prefix used when naming APK assets in a GitHub Release.
  /// Full pattern: `{apkAssetPrefix}-{abi}-v{version}.apk`
  static const String apkAssetPrefix = 'utang-tracker';

  /// ABI identifiers in preference order (most preferred first).
  static const List<String> supportedAbis = [
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
  ];

  static const String universalAbiName = 'universal';

  /// Minimum time between automatic startup update checks.
  static const Duration updateCheckThrottle = Duration(hours: 24);

  /// MethodChannel name shared between Dart and MainActivity.kt.
  static const String updaterChannel = 'com.example.utang_tracker/updater';
}
