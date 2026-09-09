/// SPO: App-wide constants - NO magic numbers/strings
class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'Τιμές';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Debounce
  static const Duration searchDebounce = Duration(milliseconds: 300);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxSearchResults = 10;
  
  // VAT Rates (Greece)
  static const List<double> vatRates = [0.0, 6.0, 13.0, 24.0];
  static const double defaultVatRate = 24.0;
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'Μετρητά',
    'Κάρτα',
    'Μεταφορά',
    'Επιταγή',
  ];
  
  // Units
  static const List<String> units = [
    'τεμ',
    'κιλό',
    'γραμμάρια',
    'λίτρα',
    'μέτρα',
    'συσκευασία',
  ];
}
