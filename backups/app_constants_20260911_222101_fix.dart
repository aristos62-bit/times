import '../strings/app_strings.dart';

/// SPO: App-wide constants - NO magic numbers/strings
class AppConstants {
  AppConstants._(); // coverage:ignore-line
  
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

  // Dates — όριο έγκυρων ημερομηνιών (αντί magic DateTime(2000) στα validators)
  static final DateTime minReceiptDate = DateTime(2000, 1, 1);

  // Snackbar
  static const Duration snackBarDuration = Duration(seconds: 2);
  
  // VAT Rates (Greece)
  static const List<double> vatRates = [0.0, 6.0, 13.0, 24.0];
  static const double defaultVatRate = 24.0;

  // Number boundaries (SPoT — αντί magic literals σε validators)
  static const double maxQuantity = 99999.0;
  static const double maxPrice = 999999.0;
  static const double maxDiscountPercent = 100.0;

  // Payment Methods
  static const List<String> paymentMethods = [
    'Μετρητά',
    'Κάρτα',
    'Μεταφορά',
    'Επιταγή',
  ];
  
  // Units — SPoT display strings: AppStrings (ενοποιημένο 'κιλά')
  static const List<String> units = [
    AppStrings.piece,
    AppStrings.kg,
    AppStrings.gram,
    AppStrings.liter,
    AppStrings.meter,
    AppStrings.package,
  ];
}
