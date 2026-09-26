/// Unit tests για το SPoT `PeriodType` (core/constants/app_enums.dart) —
/// §2.1 Φάση 5 Βήμα 1.
///
/// Μόνο enum declaration → plain `test()`, χωρίς widget pump (στυλ
/// app_strings_test). Persist με `.name` (pattern `SettingsRepository`
/// `mode.name`/`asNameMap`).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_enums.dart';

void main() {
  group('PeriodType', () {
    test('5 τιμές με τη σειρά day/week/month/year/custom (§2.1)', () {
      expect(PeriodType.values, [
        PeriodType.day,
        PeriodType.week,
        PeriodType.month,
        PeriodType.year,
        PeriodType.custom,
      ]);
    });

    test('.name round-trip — persist όπως ThemeMode (§2.3 pattern)', () {
      for (final period in PeriodType.values) {
        expect(
          PeriodType.values.asNameMap()[period.name],
          period,
        );
      }
    });

    test('default περιόδου = month (§2.1: default Μήνας τρέχων)', () {
      expect(PeriodType.month, isNotNull);
    });
  });
}
