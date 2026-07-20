class AppConstants {
  AppConstants._();

  static const String appName = 'Utang Tracker';
  static const String logoAsset = 'assets/images/new-logo.png';
  static const String currencySymbol = '₱';

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

  /// APK naming pattern: {prefix}-{abi}-v{version}.apk
  static const String apkAssetPrefix = 'utang-tracker';

  /// Most preferred ABI first.
  static const List<String> supportedAbis = [
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
  ];

  static const String universalAbiName = 'universal';

  /// Minimum interval between automatic update checks.
  static const Duration updateCheckThrottle = Duration(hours: 24);

  /// MethodChannel name shared between Dart and MainActivity.kt.
  static const String updaterChannel = 'com.example.utang_tracker/updater';

  static const String facebookUrl =
      'https://www.facebook.com/alduanecuevasmirasol';
}
