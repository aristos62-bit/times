/// Unit tests για το SPoT `AppStrings` (core/constants/app_strings.dart) — §1.1.
///
/// Μόνο απλές σταθερές → plain `test()`, χωρίς widget pump (ίδιο στυλ με
/// debug_config_test/app_logger_test). Τιμές επαληθευμένες λέξη-προς-λέξη
/// με το DESIGN.md (§0, §2.1, §2.2) κατά την υλοποίηση.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_strings.dart';

void main() {
  group('AppStrings', () {
    // ─── App identity (§0) ───────────────────────────────────────────────────
    test('appTitle = «Τιμές» (branding §0)', () {
      expect(AppStrings.appTitle, 'Τιμές');
    });

    // ─── Home / Stats (§2.1) ─────────────────────────────────────────────────
    test('noPricesForPeriod — ακριβές κείμενο (§2.1)', () {
      expect(
        AppStrings.noPricesForPeriod,
        'Δεν υπάρχουν καταχωρημένες τιμές για αυτή την περίοδο',
      );
    });

    test('retryButton = «Επανάληψη» (§2.1)', () {
      expect(AppStrings.retryButton, 'Επανάληψη');
    });

    // ─── Price entry (§2.2) ──────────────────────────────────────────────────
    test('saveReceipt = «Αποθήκευση Απόδειξης» (§2.2)', () {
      expect(AppStrings.saveReceipt, 'Αποθήκευση Απόδειξης');
    });

    test('addReceiptLine = «Προσθήκη γραμμής» (§2.2)', () {
      expect(AppStrings.addReceiptLine, 'Προσθήκη γραμμής');
    });

    test('field labels — ημερομηνία/προμηθευτής/ποσότητα/τιμή (§2.2)', () {
      expect(AppStrings.fieldDate, 'Ημερομηνία');
      expect(AppStrings.fieldSupplier, 'Προμηθευτής');
      expect(AppStrings.fieldQuantity, 'Ποσότητα');
      expect(AppStrings.fieldPrice, 'Τιμή');
    });

    // ─── Καθολικές εγγυήσεις (όλα τα strings) ────────────────────────────────
    test('κανένα string μη-κενό, χωρίς whitespace στα άκρα, χωρίς αλλαγή γραμμής', () {
      for (final text in _allStrings) {
        expect(text, isNotEmpty, reason: 'Βρέθηκε κενό string');
        expect(
          text,
          text.trim(),
          reason: 'String με αρχικό/τελικό whitespace: «$text»',
        );
        expect(text.contains('\n'), isFalse, reason: 'String με αλλαγή γραμμής: «$text»');
      }
    });

    // ─── ΠΡΟΣΩΡΙΝΑ template strings (default counter) ───────────────────────
    test('template counter strings — ελληνικά, όχι default Flutter template', () {
      expect(AppStrings.counterInstruction, 'Πατήσατε το κουμπί τόσες φορές:');
      expect(AppStrings.counterIncrementTooltip, 'Αύξηση');
    });
  });
}

/// Διατηρείται χειροκίνητα — προστίθεται κάθε νέο AppStrings μέλος εδώ.
/// Χρησιμοποιείται μόνο από τον καθολικό έλεγχο ποιότητας (κανένα string
/// κενό / με whitespace / με νέα γραμμή).
const List<String> _allStrings = [
  AppStrings.appTitle,
  AppStrings.noPricesForPeriod,
  AppStrings.retryButton,
  AppStrings.saveReceipt,
  AppStrings.addReceiptLine,
  AppStrings.fieldDate,
  AppStrings.fieldSupplier,
  AppStrings.fieldQuantity,
  AppStrings.fieldPrice,
  AppStrings.counterInstruction,
  AppStrings.counterIncrementTooltip,
];