// core/utils/extensions.dart
import 'currency_formatter.dart';

/// SPO: Dart extensions - reusable extensions
extension StringExtensions on String {
  /// Capitalize first letter — edge: κενό string επιστρέφει κενό (όχι RangeError)
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  
  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;
  
  /// Remove extra whitespace
  String get removeExtraWhitespace => replaceAll(RegExp(r'\s+'), ' ').trim();
}

extension DateTimeExtensions on DateTime {
  /// Check if same day
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
  
  /// Check if today
  bool get isToday => isSameDay(DateTime.now());
  
  /// Check if yesterday
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  
  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get end of day — edge: 999ms για να μην χάνονται records στο τελευταίο δευτερόλεπτο
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
  
  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  /// Get end of month — edge: 999ms (όπως endOfDay)
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);
}

extension DoubleExtensions on double {
  /// Format as currency
  String toCurrency() => CurrencyFormatter.format(this);
  
  /// Format with 2 decimal places
  String toFixed2() => toStringAsFixed(2);
  
  /// Check if approximately equal
  bool approximates(double other, {double epsilon = 0.001}) =>
      (this - other).abs() < epsilon;
}
