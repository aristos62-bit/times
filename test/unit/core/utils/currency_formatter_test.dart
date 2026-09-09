import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('1234.56 → 1.234,56€', () {
      expect(CurrencyFormatter.format(1234.56), '1.234,56€');
    });

    test('αρνητικό ποσό', () {
      expect(CurrencyFormatter.format(-50.0), '-50,00€');
    });

    test('custom νόμισμα', () {
      expect(CurrencyFormatter.format(10.0, currency: r'$'), '10,00\$');
    });
  });

  group('CurrencyFormatter.formatWithSign', () {
    test('θετικό με +', () {
      expect(CurrencyFormatter.formatWithSign(1234.56), '+1.234,56€');
    });
  });

  group('CurrencyFormatter.tryParse', () {
    test('1.234,56€ → 1234.56', () {
      expect(CurrencyFormatter.tryParse('1.234,56€'), 1234.56);
    });

    test('ελληνικό κόμμα 1,5 → 1.5', () {
      expect(CurrencyFormatter.tryParse('1,5'), 1.5);
    });

    test('κενό → null (όχι crash)', () {
      expect(CurrencyFormatter.tryParse(''), isNull);
      expect(CurrencyFormatter.tryParse('   '), isNull);
    });

    test('invalid → null (όχι crash)', () {
      expect(CurrencyFormatter.tryParse('abc'), isNull);
      expect(CurrencyFormatter.tryParse('-'), isNull);
    });

    test('custom νόμισμα', () {
      expect(
        CurrencyFormatter.tryParse('1.234,56\$', currency: r'$'),
        1234.56,
      );
    });
  });

  group('CurrencyFormatter.parse', () {
    test('έγκυρο', () {
      expect(CurrencyFormatter.parse('1.234,56€'), 1234.56);
    });

    test('άκυρο → FormatException', () {
      expect(() => CurrencyFormatter.parse('abc'), throwsFormatException);
    });
  });
}
