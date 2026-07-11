/// App-wide constants. Payment methods and units are UI constraints only
/// (stored as free TEXT per database rules).
class AppConstants {
  AppConstants._();

  static const String appName = 'Utang Tracker';
  static const String logoAsset = 'assets/images/new_logo.png';
  static const String currencySymbol = '₱';

  static const List<String> paymentMethods = [
    'Cash',
    'GCash',
    'Bank Transfer',
    'Other',
  ];

  static const int recentItemsLimit = 5;
}
