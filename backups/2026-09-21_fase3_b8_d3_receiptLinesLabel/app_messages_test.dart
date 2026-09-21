/// Unit tests για το SPoT `AppMessages` (core/constants/app_messages.dart) — §1.1.
///
/// Μόνο απλές σταθερές/μέθοδοι → plain `test()`, χωρίς widget pump (ίδιο στυλ με
/// app_strings_test). Τιμές επαληθευμένες λέξη-προς-λέξη με το DESIGN.md
/// (§2.2, §2.3, §2.4) κατά την υλοποίηση.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_messages.dart';

void main() {
  group('AppMessages', () {
    // ─── SnackBar success (§2.2, §2.3) ──────────────────────────────────────
    test('savedReceipt = «Αποθήκευση επιτυχής» (§2.2)', () {
      expect(AppMessages.savedReceipt, 'Αποθήκευση επιτυχής');
    });

    test('restoreSuccess = «Η επαναφορά ολοκληρώθηκε» (§2.3)', () {
      expect(AppMessages.restoreSuccess, 'Η επαναφορά ολοκληρώθηκε');
    });

    // ─── Supplier create / dup (§2.4 · Φάση 3 Βήμα 3) ────────────────────────
    test('supplierAdded = «Ο προμηθευτής προστέθηκε» (§2.4)', () {
      expect(AppMessages.supplierAdded, 'Ο προμηθευτής προστέθηκε');
    });

    test('supplierExists = «Ο προμηθευτής υπάρχει ήδη» (§2.4)', () {
      expect(AppMessages.supplierExists, 'Ο προμηθευτής υπάρχει ήδη');
    });

    // ─── Item create / dup (§2.4 · Φάση 3 Βήμα 4) ───────────────────────────
    test('itemAdded = «Το είδος προστέθηκε» (§2.4)', () {
      expect(AppMessages.itemAdded, 'Το είδος προστέθηκε');
    });

    test('itemExists = «Το είδος υπάρχει ήδη» (§2.4)', () {
      expect(AppMessages.itemExists, 'Το είδος υπάρχει ήδη');
    });

    test("itemNotFound('γαλα') — δυναμικό μήνυμα (§2.4)", () {
      expect(AppMessages.itemNotFound('γαλα'), 'Δεν βρέθηκε είδος "γαλα"');
    });

    test('receiptLinesLimitReached(100) — δυναμικό μήνυμα (§2.2 · Β5ε-2)', () {
      expect(
        AppMessages.receiptLinesLimitReached(100),
        'Η απόδειξη έχει φτάσει το όριο των 100 γραμμών',
      );
    });

    test('receiptNumber(12) — label αριθμού απόδειξης (§2.2 · Βήμα 7)', () {
      expect(AppMessages.receiptNumber(12), 'Απόδειξη #12');
    });

    test('receiptLinesLabel(3) — ένδειξη πλήθους γραμμών (§2.2 · Βήμα 7)', () {
      expect(AppMessages.receiptLinesLabel(3), '3 γραμμές');
    });

    // ─── Confirm dialog defaults (§2.4) ─────────────────────────────────────
    test('confirmDialogTitle = «Επιβεβαίωση» (§2.4)', () {
      expect(AppMessages.confirmDialogTitle, 'Επιβεβαίωση');
    });

    test('confirmDialogConfirm = «Ναι» (§2.4)', () {
      expect(AppMessages.confirmDialogConfirm, 'Ναι');
    });

    test('confirmDialogCancel = «Ακύρωση» (§2.4)', () {
      expect(AppMessages.confirmDialogCancel, 'Ακύρωση');
    });

    // ─── Confirm messages (§2.2.221) ────────────────────────────────────────
    test('exitUnsavedConfirm — ακριβές κείμενο (§2.2.221)', () {
      expect(
        AppMessages.exitUnsavedConfirm,
        'Έχετε μη αποθηκευμένες γραμμές. Έξοδος χωρίς αποθήκευση;',
      );
    });

    // ─── Dynamic tooltips (§2.3.252) ────────────────────────────────────────
    test('itemCountTooltip(0) — edge case (§2.3.252)', () {
      expect(
        AppMessages.itemCountTooltip(0),
        'Δεν μπορεί να διαγραφεί: περιέχει 0 είδη',
      );
    });

    test('itemCountTooltip(5) — typical (§2.3.252)', () {
      expect(
        AppMessages.itemCountTooltip(5),
        'Δεν μπορεί να διαγραφεί: περιέχει 5 είδη',
      );
    });

    // ─── Pattern check ──────────────────────────────────────────────────────
    test('itemCountTooltip είναι static method, επιστρέφει String', () {
      expect(AppMessages.itemCountTooltip(1), isA<String>());
    });

    // ─── Καθολικός έλεγχος ποιότητας (ίδιο pattern με app_strings_test) ─────
    test('κανένα const string μη-κενό, χωρίς whitespace στα άκρα, χωρίς \\n', () {
      for (final text in _allConstStrings) {
        expect(text, isNotEmpty, reason: 'Βρέθηκε κενό string');
        expect(text, text.trim(), reason: 'Whitespace στα άκρα: «$text»');
        expect(text.contains('\n'), isFalse, reason: 'Αλλαγή γραμμής: «$text»');
      }
    });
  });
}

/// Χειροκίνητα συντηρούμενη λίστα — προστίθεται κάθε νέο const member.
/// Χρησιμοποιείται μόνο από τον καθολικό έλεγχο ποιότητας.
const List<String> _allConstStrings = [
  AppMessages.savedReceipt,
  AppMessages.restoreSuccess,
  AppMessages.supplierAdded,
  AppMessages.supplierExists,
  AppMessages.itemAdded,
  AppMessages.itemExists,
  AppMessages.confirmDialogTitle,
  AppMessages.confirmDialogConfirm,
  AppMessages.confirmDialogCancel,
  AppMessages.exitUnsavedConfirm,
];
