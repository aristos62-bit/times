// core/utils/currency_formatter.dart
/// SPO: Currency formatting - single source of truth
class CurrencyFormatter {
  CurrencyFormatter._();
  
  static const String _defaultCurrency = '€';
  static const int _decimalPlaces = 2;
  
  /// Format: 1234.56 → "1.234,56€"
  static String format(double amount, {String currency = _defaultCurrency}) {
    final formatted = amount
        .toStringAsFixed(_decimalPlaces)
        .replaceAll('.', ',')
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return '$formatted$currency';
  }
  
  /// Format with sign: 1234.56 → "+1.234,56€", -50.00 → "-50,00€"
  static String formatWithSign(double amount, {String currency = _defaultCurrency}) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${format(amount, currency: currency)}';
  }
  
  /// Parse: "1.234,56€" → 1234.56
  static double parse(String formatted) {
    final cleaned = formatted
        .replaceAll(_defaultCurrency, '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.parse(cleaned);
  }
}
