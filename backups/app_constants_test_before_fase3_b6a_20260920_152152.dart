/// Unit tests για το SPoT `AppConstants` (core/constants/app_constants.dart) — §1.1.
///
/// Μόνο απλές σταθερές → plain `test()`, χωρίς widget pump (ίδιο στυλ με
/// app_strings_test/app_messages_test/app_errors_test). Τιμές επαληθευμένες
/// με το DESIGN.md (§1.4, §2.0, §2.2, §2.3) κατά την υλοποίηση · επιπλέον
/// invariants (ordering/positiveness) που δεν γράφονται ρητά στο DESIGN αλλά
/// προκύπτουν από τη σημασιολογία των σταθερών.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    // ─── Responsive breakpoints (§1.4) ───────────────────────────────────────
    test('mobileMaxWidth = 600 (mobile layout κάτω από αυτό)', () {
      expect(AppConstants.mobileMaxWidth, 600.0);
    });

    test('tabletMaxWidth = 1024 (desktop layout πάνω από αυτό)', () {
      expect(AppConstants.tabletMaxWidth, 1024.0);
    });

    test('breakpoint ordering: mobileMaxWidth < tabletMaxWidth', () {
      expect(
        AppConstants.mobileMaxWidth,
        lessThan(AppConstants.tabletMaxWidth),
        reason: 'Αλλιώς δεν ορίζεται mobile/tablet/desktop ζώνη',
      );
    });

    // ─── Spacing (κλιμακατό) ─────────────────────────────────────────────────
    test('spacing κλίμακα — S/M/L/XL ακριβείς τιμές', () {
      expect(AppConstants.spacingS, 4.0);
      expect(AppConstants.spacingM, 8.0);
      expect(AppConstants.spacingL, 16.0);
      expect(AppConstants.spacingXL, 24.0);
    });

    test('spacing ordering: S < M < L < XL', () {
      final values = [
        AppConstants.spacingS,
        AppConstants.spacingM,
        AppConstants.spacingL,
        AppConstants.spacingXL,
      ];
      for (var i = 0; i < values.length - 1; i++) {
        expect(values[i], lessThan(values[i + 1]));
      }
    });

    // ─── Radius ───────────────────────────────────────────────────────────────
    test('radius κλίμακα — S/M/L ακριβείς τιμές', () {
      expect(AppConstants.radiusS, 8.0);
      expect(AppConstants.radiusM, 12.0);
      expect(AppConstants.radiusL, 16.0);
    });

    test('radius ordering: S < M < L', () {
      final values = [
        AppConstants.radiusS,
        AppConstants.radiusM,
        AppConstants.radiusL,
      ];
      for (var i = 0; i < values.length - 1; i++) {
        expect(values[i], lessThan(values[i + 1]));
      }
    });

    // ─── Search / Autocomplete (§2.2) ────────────────────────────────────────
    test('searchDebounceMillis = 250 (debounce αναζήτησης, §2.0.3)', () {
      expect(AppConstants.searchDebounceMillis, 250);
    });

    test('searchMinChars = 1 (αναζήτηση από το 1ο γράμμα)', () {
      expect(AppConstants.searchMinChars, 1);
    });

    test('searchResultsLimit = 15 (πάνω όριο αποτελεσμάτων, §1.4)', () {
      expect(AppConstants.searchResultsLimit, 15);
    });

    test('searchDropdownMaxHeight = 320 (max height overlay, §2.4)', () {
      expect(AppConstants.searchDropdownMaxHeight, 320.0);
    });

    test('search invariants: debounce > 0, minChars ≥ 1, limit > minChars', () {
      expect(AppConstants.searchDebounceMillis, greaterThan(0));
      expect(AppConstants.searchMinChars, greaterThanOrEqualTo(1));
      expect(AppConstants.searchResultsLimit, greaterThan(AppConstants.searchMinChars));
    });

    // ─── Validation (§2.2) ────────────────────────────────────────────────────
    test('validationMinPrice = 0 (αποκλειστικό κατώτατο)', () {
      expect(AppConstants.validationMinPrice, 0.0);
    });

    test('validationMinQuantity = 0 (αποκλειστικό κατώτατο)', () {
      expect(AppConstants.validationMinQuantity, 0.0);
    });

    test('maxItemNameLength = 100 (όνομα Είδους/Κατηγορίας κλπ)', () {
      expect(AppConstants.maxItemNameLength, 100);
      expect(AppConstants.maxItemNameLength, greaterThan(0));
    });

    // ─── Numeric / Precision ─────────────────────────────────────────────────
    test('priceDecimalDigits = 2 (εμφάνιση €)', () {
      expect(AppConstants.priceDecimalDigits, 2);
    });

    test('quantityDecimalDigits = 3 (όριο εισόδου ποσότητας)', () {
      expect(AppConstants.quantityDecimalDigits, 3);
    });

    test('defaultReceiptQuantity = 1.0 (αρχική ποσότητα γραμμής)', () {
      expect(AppConstants.defaultReceiptQuantity, 1.0);
    });

    test('quantityDecimalDigits > priceDecimalDigits (ποσότητα δεκτική κλασμάτων)', () {
      expect(
        AppConstants.quantityDecimalDigits,
        greaterThan(AppConstants.priceDecimalDigits),
      );
    });

    // ─── Numeric / Limits (Φάση 3 Βήμα 5) ────────────────────────────────────
    test('priceMaxLength = 10 (input limit πεδίου τιμής, Β5)', () {
      expect(AppConstants.priceMaxLength, 10);
    });

    test('quantityMaxLength = 11 (input limit πεδίου ποσότητας, Β5)', () {
      expect(AppConstants.quantityMaxLength, 11);
    });

    test('maxPriceCents = 9999999 (€99.999,99, Β5)', () {
      expect(AppConstants.maxPriceCents, 9999999);
    });

    test('maxQuantity = 1000000.0 (άνω όριο ποσότητας, Β5)', () {
      expect(AppConstants.maxQuantity, 1000000.0);
    });

    test('Β5 limits invariants: όλα > 0 και length ≥ μέγιστο έγκυρο κείμενο', () {
      expect(AppConstants.priceMaxLength, greaterThan(0));
      expect(AppConstants.quantityMaxLength, greaterThan(0));
      expect(AppConstants.maxPriceCents, greaterThan(0));
      expect(AppConstants.maxQuantity, greaterThan(0));
      // Μέγιστο έγκυρο κείμενο τιμής = €99.999,99 → «99999,99» (8 χαρακτήρες).
      expect('99999,99'.length, 8);
      expect(
        AppConstants.priceMaxLength,
        greaterThanOrEqualTo('99999,99'.length),
      );
      // Μέγιστο έγκυρο κείμενο ποσότητας = «1000000,000» (11 χαρακτήρες).
      expect('1000000,000'.length, 11);
      expect(
        AppConstants.quantityMaxLength,
        greaterThanOrEqualTo('1000000,000'.length),
      );
    });

    // ─── Lists / Limits ──────────────────────────────────────────────────────
    test('recentReceiptsLimit = 20 (placeholder λίστα, Φάση 3)', () {
      expect(AppConstants.recentReceiptsLimit, 20);
    });

    test('maxReceiptLines = 100 (καλάθι απόδειξης, §2.2)', () {
      expect(AppConstants.maxReceiptLines, 100);
    });

    test('limits invariants: όλα > 0, lines >= items limit', () {
      expect(AppConstants.recentReceiptsLimit, greaterThan(0));
      expect(AppConstants.maxReceiptLines, greaterThan(0));
      expect(AppConstants.maxReceiptLines, greaterThanOrEqualTo(AppConstants.maxItemNameLength));
    });

    // ─── Timing / UX (§2.0.6) ────────────────────────────────────────────────
    test('snackBarDurationSeconds = 4 (AppFeedback, §2.0.6)', () {
      expect(AppConstants.snackBarDurationSeconds, 4);
    });

    test('maxFeedbackLines = 3 (safety net overflow, §1.4)', () {
      expect(AppConstants.maxFeedbackLines, 3);
    });

    test('timing invariants: duration > 0, maxFeedbackLines > 0', () {
      expect(AppConstants.snackBarDurationSeconds, greaterThan(0));
      expect(AppConstants.maxFeedbackLines, greaterThan(0));
    });

    // ─── Date picker (Φάση 3 Βήμα 2) ────────────────────────────────────────
    test('datePickerFirstYear = 2000 (firstDate showDatePicker)', () {
      expect(AppConstants.datePickerFirstYear, 2000);
    });

    test('datePickerLastYear = 2100 (lastDate showDatePicker)', () {
      expect(AppConstants.datePickerLastYear, 2100);
    });

    test('date picker bounds invariant: firstYear < lastYear', () {
      expect(
        AppConstants.datePickerFirstYear,
        lessThan(AppConstants.datePickerLastYear),
        reason: 'Αλλιώς το εύρος ημερομηνιών του picker είναι κενό',
      );
    });

    // ─── Backup (§2.3) ───────────────────────────────────────────────────────
    test('backupFileNamePattern — template ονομασίας (§2.3)', () {
      expect(AppConstants.backupFileNamePattern, 'times_backup_yyyyMMdd_HHmmss');
    });

    test('backupFileNamePattern — φέρνει τα απαραίτητα τμήματα ημερομηνίας/ώρας', () {
      final p = AppConstants.backupFileNamePattern;
      expect(p, contains('times_backup_'));
      expect(p, contains('yyyy'));
      expect(p, contains('MM'));
      expect(p, contains('dd'));
      expect(p, contains('HH'));
      expect(p, contains('mm'));
      expect(p, contains('ss'));
    });

    // ─── Καθολικός έλεγχος ποιότητας (ίδιο pattern με app_errors_test) ───────
    test('κανένα string μη-κενό, χωρίς whitespace στα άκρα, χωρίς \\n', () {
      for (final text in _allConstStrings) {
        expect(text, isNotEmpty, reason: 'Βρέθηκε κενό string');
        expect(text, text.trim(), reason: 'Whitespace στα άκρα: «$text»');
        expect(text.contains('\n'), isFalse, reason: 'Αλλαγή γραμμής: «$text»');
      }
    });
  });
}

/// Χειροκίνητα συντηρούμενη λίστα — προστίθεται κάθε νέο String const μέλος.
/// Χρησιμοποιείται μόνο από τον καθολικό έλεγχο ποιότητας.
const List<String> _allConstStrings = [
  AppConstants.backupFileNamePattern,
];