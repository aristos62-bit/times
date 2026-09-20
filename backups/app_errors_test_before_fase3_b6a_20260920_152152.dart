/// Unit tests για το SPoT `AppErrors` (core/constants/app_errors.dart) — §1.1.
///
/// Μόνο απλές σταθερές → plain `test()`, χωρίς widget pump (ίδιο στυλ με
/// app_strings_test/app_messages_test). Τιμές επαληθευμένες λέξη-προς-λέξη
/// με το DESIGN.md (§2.1, §2.2, §2.3, §2.4) κατά την υλοποίηση.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';

void main() {
  group('AppErrors', () {
    // ─── DB / Data (§2.1, §2.2) ──────────────────────────────────────────────
    test('saveFailed = «Σφάλμα κατά την αποθήκευση» (§2.2)', () {
      expect(AppErrors.saveFailed, 'Σφάλμα κατά την αποθήκευση');
    });

    test('loadDataFailed — generic σφάλμα φόρτωσης (§2.1 + §2.4)', () {
      expect(AppErrors.loadDataFailed, 'Σφάλμα κατά τη φόρτωση δεδομένων');
    });

    // ─── Backup / Restore (§2.3) ─────────────────────────────────────────────
    test('backupFailed = «Σφάλμα κατά τη δημιουργία αντιγράφου» (§2.3)', () {
      expect(AppErrors.backupFailed, 'Σφάλμα κατά τη δημιουργία αντιγράφου');
    });

    test('invalidBackupFile — άκυρο αρχείο validation (§2.3)', () {
      expect(
        AppErrors.invalidBackupFile,
        'Το αρχείο δεν είναι έγκυρο αντίγραφο της βάσης',
      );
    });

    test('restoreFailed = «Σφάλμα κατά την επαναφορά αντιγράφου» (§2.3)', () {
      expect(AppErrors.restoreFailed, 'Σφάλμα κατά την επαναφορά αντιγράφου');
    });

    // ─── Validation (§2.2:214-218 · Φάση 3 Βήμα 4) ───────────────────────────
    test('nameRequired = «Το όνομα είναι υποχρεωτικό» (§2.2)', () {
      expect(AppErrors.nameRequired, 'Το όνομα είναι υποχρεωτικό');
    });

    test('nameTooLong = «Το όνομα είναι πολύ μεγάλο» (§2.2)', () {
      expect(AppErrors.nameTooLong, 'Το όνομα είναι πολύ μεγάλο');
    });

    // ─── Καθολικός έλεγχος ποιότητας (ίδιο pattern με app_messages_test) ─────
    test('κανένα string μη-κενό, χωρίς whitespace στα άκρα, χωρίς \\n', () {
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
  AppErrors.saveFailed,
  AppErrors.loadDataFailed,
  AppErrors.backupFailed,
  AppErrors.invalidBackupFile,
  AppErrors.restoreFailed,
  AppErrors.nameRequired,
  AppErrors.nameTooLong,
];