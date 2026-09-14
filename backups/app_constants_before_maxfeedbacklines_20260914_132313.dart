/// SPoT: Αριθμητικές και στατικές τιμές (paddings, διαστήματα, durations,
/// breakpoints, όρια, λογικά μεγέθη).
///
/// Κανόνας: τίποτα hardcoded σε UI/logic — όλες οι αριθμητικές τιμές
/// περνούν από εδώ. Τα typography μεγέθη ΔΕΝ είναι εδώ (βλ. app_theme.dart).
library;

/// Abstract SPoT class — μόνο σταθερές, δεν instantiate.
abstract final class AppConstants {
  // ─── Responsive breakpoints ────────────────────────────────────────────────
  // Κάτω από mobileMaxWidth → mobile layout.
  static const double mobileMaxWidth = 600.0;

  // Κάτω από tabletMaxWidth → tablet layout · πάνω → desktop layout.
  static const double tabletMaxWidth = 1024.0;

  // ─── Spacing (κλιμακωτό) ───────────────────────────────────────────────────
  static const double spacingS = 4.0;
  static const double spacingM = 8.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 24.0;

  // ─── Radius ────────────────────────────────────────────────────────────────
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;

  // ─── Search / Autocomplete (§2.2 DESIGN) ──────────────────────────────────
  // Debounce πριν την αναζήτηση στη βάση.
  static const int searchDebounceMillis = 250;

  // Ελάχιστοι χαρακτήρες για να πυροδοτηθεί η αναζήτηση («ανά γράμμα» →
  // το 1 γράμμα ξεκινάει άμεσα).
  static const int searchMinChars = 1;

  // Πάνω όριο αποτελεσμάτων που εμφανίζονται — αποτρέπει overflow της λίστας
  // όταν το searchMinChars=1 επιστρέφει πολλά αποτελέσματα (§1.4).
  static const int searchResultsLimit = 15;

  // ─── Validation όρια ───────────────────────────────────────────────────────
  // ΑΠΟΚΛΕΙΣΤΙΚΟ όριο — όχι αποδεκτή τιμή. Δεκτό μόνο price > validationMinPrice.
  static const double validationMinPrice = 0.0;

  // ΑΠΟΚΛΕΙΣΤΙΚΟ όριο — όχι αποδεκτή τιμή. Δεκτό μόνο quantity > validationMinQuantity.
  static const double validationMinQuantity = 0.0;

  // Μέγιστο μήκος ονόματος για Είδος/Κατηγορία/Υποκατηγορία/Προμηθευτή.
  static const int maxItemNameLength = 100;

  // ─── Numeric / Precision ───────────────────────────────────────────────────
  // Πόσα δεκαδικά δείχνει το UI όταν εμφανίζει τιμή (priceCents / 100).
  // ΜΟΝΟ formatting — η αποθήκευση είναι πάντα ακέραιος σε λεπτά (cents).
  static const int priceDecimalDigits = 2;

  // Πόσα δεκαδικά δέχεται το πεδίο ποσότητας στη φόρμα εισαγωγής.
  // ΜΟΝΟ όριο εισόδου (π.χ. 0.5555 κιλά → απορρίπτεται). Η αποθήκευση
  // του quantity είναι REAL στο Drift.
  static const int quantityDecimalDigits = 3;

  // Default ποσότητα όταν ανοίγει νέα γραμμή απόδειξης.
  static const double defaultReceiptQuantity = 1.0;

  // ─── Lists / Limits ────────────────────────────────────────────────────────
  // Πλήθος τελευταίων αποδείξεων στη placeholder λίστα (Φάση 3).
  static const int recentReceiptsLimit = 20;

  // Μέγιστες γραμμές ειδών ανά απόδειξη (καλάθι).
  static const int maxReceiptLines = 100;

  // ─── Timing / UX ───────────────────────────────────────────────────────────
  // Διάρκεια εμφάνισης SnackBar μηνυμάτων επιβεβαίωσης.
  static const int snackBarDurationSeconds = 4;

  // ─── Backup (§2.3 DESIGN) ──────────────────────────────────────────────────
  // Pattern ονομασίας αρχείων backup — βλ. DESIGN.md §2.3.
  // Χρησιμοποιεί το πρότυπο ημερομηνίας (yyyy=έτος, MM=μήνας, dd=ημέρα,
  // HH=ώρα, mm=λεπτά, ss=δευτερόλεπτα).
  static const String backupFileNamePattern = 'times_backup_yyyyMMdd_HHmmss';
}