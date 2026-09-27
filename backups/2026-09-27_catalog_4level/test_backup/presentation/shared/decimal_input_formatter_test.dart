/// Unit tests για το SPoT `DecimalInputFormatter` (presentation/shared).
/// Φάση 3 Βήμα 5 — καθαριστής εισόδου (sanitizer).
///
/// Test IDs: B5α-DF1..N (formatting rules).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:times/presentation/shared/decimal_input_formatter.dart';

TextEditingValue _value(String text) => TextEditingValue(text: text);

/// Βοηθητικό: τρέχει τον formatter και επιστρέφει το καθαρισμένο κείμενο.
String? format(DecimalInputFormatter formatter, String input) {
  final result =
      formatter.formatEditUpdate(TextEditingValue.empty, _value(input));
  return result.text.isEmpty ? null : result.text;
}

void main() {
  group('DecimalInputFormatter (βασικός καθαρισμός)', () {
    test('DF1: επιτρέπει μόνο ψηφία σε integer-only mode', () {
      const f = DecimalInputFormatter(allowDecimal: false, maxLength: 5);
      expect(format(f, '123'), '123');
      expect(format(f, '12a3b'), '123');
      expect(format(f, '1.2.3'), '123');
      expect(format(f, ',5'), '5');
      expect(format(f, ''), null);
    });

    test('DF2: επιτρέπει διαχωριστή (.) και (,) σε decimal mode', () {
      const f = DecimalInputFormatter(allowDecimal: true);
      expect(format(f, '1.5'), '1.5');
      expect(format(f, '1,5'), '1,5');
      expect(format(f, '1.2,3'), '1.23'); // κρατά τον πρώτο
      expect(format(f, '1,2.3'), '1,23'); // κρατά τον πρώτο
    });

    test('DF3: κρατά μόνο τον ΠΡΩΤΟ διαχωριστή', () {
      const f = DecimalInputFormatter(allowDecimal: true, maxDecimalDigits: 2);
      expect(format(f, '1,2,3'), '1,23');
      expect(format(f, '1.2.3.4'), '1.23');
      expect(format(f, '1.2.3.4.5'), '1.23');
    });

    test('DF4: προθήκη 0 αν λείπει το ακέραιο μέρος (",5" → "0,5")', () {
      const f = DecimalInputFormatter(allowDecimal: true);
      expect(format(f, ',5'), '0,5');
      expect(format(f, '.5'), '0.5');
      expect(format(f, '.'), null);   // μόνο διαχωριστής → κενό
      expect(format(f, ','), null);   // ίδιο
    });

    test('DF5: όριο δεκαδικών ψηφίων', () {
      const f2 = DecimalInputFormatter(allowDecimal: true, maxDecimalDigits: 2);
      expect(format(f2, '1,555'), '1,55');  // περικοπή
      expect(format(f2, '1,55'), '1,55');   // ακριβώς 2 → ΟΚ
      expect(format(f2, '1,5'), '1,5');     // 1 δεκαδικό → ΟΚ
      expect(format(f2, '1,'), '1,');       // separator χωρίς decimals → επιτρέπεται

      const f3 = DecimalInputFormatter(allowDecimal: true, maxDecimalDigits: 3);
      expect(format(f3, '1,5555'), '1,555');
      expect(format(f3, '1,555'), '1,555');
    });

    test('DF6: maxLength περιορίζει συνολικό μήκος', () {
      const f = DecimalInputFormatter(allowDecimal: true, maxLength: 6);
      expect(format(f, '123,456'), '123,45'); // 7 chars → περικοπή
      expect(format(f, '123,45'), '123,45');   // 6 chars → ΟΚ
      expect(format(f, '123456789'), '123456'); // maxLength 6
    });

    test('DF7: κενό είσοδος → null', () {
      const f = DecimalInputFormatter(allowDecimal: true);
      expect(format(f, ''), null);
      expect(format(f, '   '), null); // spaces stripped
    });

    test('DF8: selection → collapsed offset στο τέλος μετά από αλλαγή', () {
      const f = DecimalInputFormatter(allowDecimal: true);
      final result = f.formatEditUpdate(
        TextEditingValue.empty,
        _value('12,5a'),
      );
      // «a» κόπηκε → κείμενο «12,5», cursor στο τέλος (4).
      expect(result.text, '12,5');
      expect(result.selection.baseOffset, 4);
      expect(result.selection.isCollapsed, isTrue);
    });

    test('DF9: unchanged text → επιστρέφει το αρχικό newValue (selection intact)', () {
      const f = DecimalInputFormatter(allowDecimal: true);
      final original = _value('12,5');
      final result = f.formatEditUpdate(TextEditingValue.empty, original);
      expect(identical(result, original), isTrue); // preserve reference
    });
  });
}