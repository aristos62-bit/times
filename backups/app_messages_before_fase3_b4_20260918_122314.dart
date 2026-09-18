/// SPoT: Δυναμικά μηνύματα ροής (SnackBar «Αποθήκευση επιτυχής», confirm
/// dialogs, tooltips) — «τι ενημερώνει τη ροή».
library;

/// Abstract SPoT class — μόνο σταθερές/μέθοδοι, δεν instantiate (pattern AppConstants).
abstract final class AppMessages {
  // ─── SnackBar success (§2.2, §2.3) ────────────────────────────────────────
  /// Επιτυχής αποθήκευση απόδειξης (§2.2: "AppFeedback.showSuccess").
  /// Αναφέρεται ήδη στο app_feedback.dart docstring (γραμμή 5).
  static const String savedReceipt = 'Αποθήκευση επιτυχής';

  /// Επιτυχής επαναφορά backup (§2.3: "AppFeedback.showSuccess").
  static const String restoreSuccess = 'Η επαναφορά ολοκληρώθηκε';

  /// Νέος προμηθευτής δημιουργήθηκε inline από το «+» (§2.4 · Φάση 3 Βήμα 3).
  static const String supplierAdded = 'Ο προμηθευτής προστέθηκε';

  /// Ο προμηθευτής υπάρχει ήδη — ο υπάρχων επιλέχθηκε (§2.4 soft dup-check).
  static const String supplierExists = 'Ο προμηθευτής υπάρχει ήδη';

  // ─── Confirm dialog defaults (§2.4 ConfirmDialog) ─────────────────────────
  /// §2.4: "ConfirmDialog — τίτλος/μήνυμα/actions από παραμέτρους, SPoT strings".
  /// Default τίτλος επιβεβαιωτικού dialog.
  static const String confirmDialogTitle = 'Επιβεβαίωση';

  /// §2.4: Default κουμπί επιβεβαίωσης.
  static const String confirmDialogConfirm = 'Ναι';

  /// §2.4: Default κουμπί ακύρωσης.
  static const String confirmDialogCancel = 'Ακύρωση';

  // ─── Confirm messages (§2.2.221) ──────────────────────────────────────────
  /// §2.2.221: "Έχετε μη αποθηκευμένες γραμμές. Έξοδος χωρίς αποθήκευση;"
  /// Χρησιμοποιείται στο PopScope/onExit της φόρμας (§2.2).
  static const String exitUnsavedConfirm =
      'Έχετε μη αποθηκευμένες γραμμές. Έξοδος χωρίς αποθήκευση;';

  // ─── Dynamic tooltips (§2.3.252) ──────────────────────────────────────────
  /// §2.3.252: "Δεν μπορεί να διαγραφεί: περιέχει X είδη".
  /// Η μόνη method στο class (όχι const) — παραβιάζει το static const String
  /// pattern αλλά είναι απαραίτητο για δυναμικό περιεχόμενο.
  static String itemCountTooltip(int count) =>
      'Δεν μπορεί να διαγραφεί: περιέχει $count είδη';
}
