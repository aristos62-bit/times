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

  // ─── Item create / dup (§2.4 · Φάση 3 Βήμα 4) ─────────────────────────────
  /// Νέο είδος δημιουργήθηκε inline από το «+» (§2.4 · Φάση 3 Βήμα 4).
  static const String itemAdded = 'Το είδος προστέθηκε';

  /// Το είδος υπάρχει ήδη — ο υπάρχων επιλέχθηκε (§2.4 soft dup-check).
  static const String itemExists = 'Το είδος υπάρχει ήδη';

  // ─── Dynamic item search (§2.4 · Φάση 3 Βήμα 4) ────────────────────────────
  /// Η μόνη method (μη-const) για δυναμικό περιεχόμενο — ίδιο pattern με
  /// `itemCountTooltip`: μήνυμα «δεν βρέθηκε» με το πληκτρολογημένο query.
  static String itemNotFound(String query) => 'Δεν βρέθηκε είδος "$query"';

  // ─── Όριο καλαθιού (§2.2 · Φάση 3 Βήμα 5ε-2) ──────────────────────────────
  /// Inline ενημέρωση όταν το «καλάθι» φτάσει το `AppConstants.maxReceiptLines`.
  /// Το όριο δίνεται ως όρισμα (SPoT — το κείμενο δεν το σκληροκωδικοποιεί).
  static String receiptLinesLimitReached(int max) =>
      'Η απόδειξη έχει φτάσει το όριο των $max γραμμών';

  // ─── Λίστα πρόσφατων αποδείξεων (§2.2 · Φάση 3 Βήμα 7) ─────────────────────
  /// Label του αριθμού (id) απόδειξης στη λίστα — «Απόδειξη #12».
  static String receiptNumber(int id) => 'Απόδειξη #$id';

  /// Ένδειξη πλήθους γραμμών απόδειξης στη λίστα — «3 γραμμές».
  static String receiptLinesLabel(int count) => '$count γραμμές';

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

  // ─── Categories CRUD (§2.3 · Φάση 4 Βήμα 4) ─────────────────────────────
  /// Κατηγορία δημιουργήθηκε από τον tree editor (§2.3 · Βήμα 4).
  static const String categoryAdded = 'Η κατηγορία προστέθηκε';

  /// Το όνομα κατηγορίας ενημερώθηκε (§2.3 · Βήμα 4).
  static const String categoryUpdated = 'Η κατηγορία ενημερώθηκε';

  /// Κατηγορία διαγράφηκε (cascade, §2.3 · Βήμα 4).
  static const String categoryDeleted = 'Η κατηγορία διαγράφηκε';

  /// Υποκατηγορία δημιουργήθηκε (§2.3 · Βήμα 4).
  static const String subCategoryAdded = 'Η υποκατηγορία προστέθηκε';

  /// Το όνομα υποκατηγορίας ενημερώθηκε (§2.3 · Βήμα 4).
  static const String subCategoryUpdated = 'Η υποκατηγορία ενημερώθηκε';

  /// Υποκατηγορία διαγράφηκε (cascade, §2.3 · Βήμα 4).
  static const String subCategoryDeleted = 'Η υποκατηγορία διαγράφηκε';

  // ─── Blocked delete + cascade confirm (§2.3 · Βήμα 4, διόρθωση Α2-1) ────
  /// Blocked tooltip: Χ είδη έχουν καταχωρημένες τιμές. Διακριτό από το
  /// `itemCountTooltip` («περιέχει») — η πύλη μετράει είδη σε χρήση
  /// (DISTINCT με ≥1 γραμμή), όχι σύνολο.
  static String itemsInUseTooltip(int count) =>
      'Δεν μπορεί να διαγραφεί: $count είδη έχουν καταχωρημένες τιμές';

  /// Cascade confirm διαγραφής κατηγορίας με [count] είδη (§2.3 · Βήμα 4).
  static String deleteCategoryConfirm(String name, int count) =>
      'Διαγραφή κατηγορίας "$name" με $count είδη; Τα είδη θα διαγραφούν.';

  /// Cascade confirm διαγραφής υποκατηγορίας με [count] είδη (§2.3 · Βήμα 4).
  static String deleteSubCategoryConfirm(String name, int count) =>
      'Διαγραφή υποκατηγορίας "$name" με $count είδη; Τα είδη θα διαγραφούν.';

  // ─── Suppliers CRUD (§2.3 · 24-09-2026) ───────────────────────────────────
  /// Το όνομα προμηθευτή ενημερώθηκε (Ρυθμίσεις).
  static const String supplierUpdated = 'Ο προμηθευτής ενημερώθηκε';

  /// Προμηθευτής διαγράφηκε (Ρυθμίσεις — μόνο καθαρός, η πύλη εγγυάται
  /// 0 αποδείξεις, RESTRICT §3).
  static const String supplierDeleted = 'Ο προμηθευτής διαγράφηκε';

  /// Confirm διαγραφής προμηθευτή (χωρίς cascade-διατύπωση — RESTRICT §3).
  static String deleteSupplierConfirm(String name) =>
      'Διαγραφή προμηθευτή "$name";';

  /// Blocked tooltip: Ν αποδείξεις του προμηθευτή (§2.3).
  static String supplierReceiptsTooltip(int count) =>
      'Δεν μπορεί να διαγραφεί: $count αποδείξεις';
}
