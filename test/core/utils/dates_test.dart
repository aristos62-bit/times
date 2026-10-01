/// Pure unit tests — SPoT `dayOnly`/`addDays` (§2.1/§2.3).
///
/// Αριθμητική ημερολογίου (overflow, Δευτέρες, αρνητικά): πράσινα σε κάθε
/// ζώνη. Χωρίς Flutter binding — καθαρές συναρτήσεις.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/utils/dates.dart';

void main() {
  group('dayOnly', () {
    test('κόβει ώρα (τοπικά μεσάνυχτα)', () {
      expect(dayOnly(DateTime(2026, 9, 16, 15, 30)), DateTime(2026, 9, 16));
    });
  });

  group('addDays', () {
    test('+1 μέσα στον μήνα', () {
      expect(addDays(DateTime(2026, 9, 16), 1), DateTime(2026, 9, 17));
    });

    test('+1 σε αλλαγή μήνα (31/1 → 1/2)', () {
      expect(addDays(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 1));
    });

    test('+1 σε αλλαγή έτους (31/12 → 1/1)', () {
      expect(addDays(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
    });

    test('−3 (πίσω, ίδιος μήνας)', () {
      expect(addDays(DateTime(2026, 3, 30), -3), DateTime(2026, 3, 27));
    });

    test('−5 (πίσω, αλλαγή μήνα)', () {
      expect(addDays(DateTime(2026, 3, 3), -5), DateTime(2026, 2, 26));
    });

    test('0 → ίδια μέρα', () {
      expect(addDays(DateTime(2026, 9, 16), 0), DateTime(2026, 9, 16));
    });

    test('+7 (εβδομάδα)', () {
      expect(addDays(DateTime(2026, 9, 14), 7), DateTime(2026, 9, 21));
    });
  });
}
