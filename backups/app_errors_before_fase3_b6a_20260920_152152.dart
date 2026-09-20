/// SPoT: Μηνύματα σφαλμάτων (validation, DB, backup) — «τι δείχνει λάθος».
///
/// Οι οθόνες/controllers εμφανίζουν ΜΟΝΟ αυτά τα strings μέσω
/// AppFeedback.showError(context, AppErrors.xxx) (§2.0.6/§1.3). Τα
/// exceptions (app_exceptions.dart) κάνουν mapping εδώ — ποτέ raw string
/// στα UI. Το logging των σφαλμάτων γίνεται στο σημείο αποτυχίας
/// (tag DB/backup/UI, debug_config), όχι εδώ — καθαρά δεδομένα.
///
/// NOTE(Φάση0-Βήμα4): τα validation messages (§2.2:214-218) προστέθηκαν στη
/// Φάση 3 Βήμα 4 μαζί με τον NameValidator — μοναδικός καταναλωτής τους.
library;

/// Abstract SPoT class — μόνο σταθερές, δεν instantiate (pattern AppConstants).
abstract final class AppErrors {
  // ─── DB / Data (§2.1, §2.2) ─────────────────────────────────────────────
  /// §2.2: αποτυχία αποθήκευσης απόδειξης → AppFeedback.showError.
  /// Αναφέρεται ήδη στο app_feedback.dart docstring (γραμμή 6).
  static const String saveFailed = 'Σφάλμα κατά την αποθήκευση';

  /// §2.1 + §2.4 (AsyncValueView): generic σφάλμα φόρτωσης δεδομένων.
  /// Εμφανίζεται σε 2+ σημεία → SPoT (§1.1).
  ///
  /// NOTE(Φάση2-Βήμα1): το `loadDataFailed` καλύπτεται προσωρινά και για
  /// write-time FK/UNIQUE σφάλματα καταλόγου (χωρίς δικό τους μήνυμα ακόμα).
  /// Θα αντικατασταθεί από ειδικό validation/conflict μήνυμα στη Φάση 3/4,
  /// μαζί με τους validators — ίδιο μοτίβο με το NOTE στο app_exceptions.dart.
  static const String loadDataFailed = 'Σφάλμα κατά τη φόρτωση δεδομένων';

  // ─── Backup / Restore (§2.3) ────────────────────────────────────────────
  /// §2.3 (Βήμα 1 Export + Βήμα 3 auto-backup): αποτυχία δημιουργίας
  /// αντιγράφου — στο Restore ακυρώνει τη διαδικασία.
  static const String backupFailed = 'Σφάλμα κατά τη δημιουργία αντιγράφου';

  /// §2.3 (Βήμα 2): το επιλεγμένο αρχείο απέτυχε τον validation
  /// (SQLite header + αναμενόμενοι πίνακες) — ΚΑΜΙΑ αλλαγή στη βάση.
  static const String invalidBackupFile =
      'Το αρχείο δεν είναι έγκυρο αντίγραφο της βάσης';

  /// §2.3 (Βήμα 4): αποτυχία αντικατάστασης/επαναφοράς μετά την επιβεβαίωση.
  static const String restoreFailed = 'Σφάλμα κατά την επαναφορά αντιγράφου';

  // ─── Validation (§2.2:214-218 · Φάση 3 Βήμα 4) ────────────────────────────
  /// §2.2: άδειο όνομα σε Κατηγορία/Υποκατηγορία/Είδος/Προμηθευτή.
  static const String nameRequired = 'Το όνομα είναι υποχρεωτικό';

  /// §2.2: όνομα πάνω από `AppConstants.maxItemNameLength` χαρακτήρες.
  static const String nameTooLong = 'Το όνομα είναι πολύ μεγάλο';
}