// core/utils/currency_formatter.dart
/// SPO: Currency formatting - single source of truth
class CurrencyFormatter {
  CurrencyFormatter._(); // coverage:ignore-line — SPoT static-only, δεν instanti-άρεται.
  
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
  
  /// Parse: "1.234,56€" → 1234.56 — edge: κενό/invalid → FormatException
  /// Χρησιμοποιεί `tryParse` εσωτερικά. Για safe parsing χρησιμοποίησε `tryParse`.
  static double parse(String formatted, {String currency = _defaultCurrency}) {
    final result = tryParse(formatted, currency: currency);
    if (result == null) {
      throw FormatException('Invalid currency format: $formatted');
    }
    return result;
  }

  /// Safe parse: "1.234,56€" → 1234.56, invalid/κενό → null (όχι crash)
  static double? tryParse(String formatted, {String currency = _defaultCurrency}) {
    if (formatted.trim().isEmpty) {
      return null;
    }
    final cleaned = formatted
        .replaceAll(currency, '')
        .replaceAll(_defaultCurrency, '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    if (cleaned.isEmpty ||
        cleaned == '-' ||
        cleaned == '+' ||
        cleaned == '.' ||
        cleaned == '-.' ||
        cleaned == '+.') {
      return null;
    }
    return double.tryParse(cleaned);
  }
}
