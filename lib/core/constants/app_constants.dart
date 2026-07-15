/// App-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Utang Tracker';
  static const String logoAsset = 'assets/images/utang_tracker_logo_v2.png';
  static const String currencySymbol = '₱';

  /// Public GitHub repo used for in-app force updates (versioned releases).
  static const String githubOwner = 'alduanemirasol';
  static const String githubRepo = 'utang_tracker';

  static const List<String> paymentMethods = [
    'Cash',
    'GCash',
    'Bank Transfer',
    'Other',
  ];

  static const int recentItemsLimit = 5;
}
