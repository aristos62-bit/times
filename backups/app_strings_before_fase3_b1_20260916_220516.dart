/// SPoT: Κείμενα εμφάνισης (labels, τίτλοι, placeholders) — «τι βλέπει ο χρήστης».
/// Μόνο ΣΤΑΤΙΚΑ κείμενα UI. Δυναμικά/εμφωλευμένα μηνύματα ροής (SnackBar,
/// confirm dialogs) → app_messages.dart · μηνύματα σφάλματος → app_errors.dart.
library;

/// Abstract SPoT class — μόνο σταθερές, δεν instantiate (pattern AppConstants).
abstract final class AppStrings {
  // ─── App identity (§0 DESIGN) ─────────────────────────────────────────────
  /// Εμφανιζόμενο όνομα εφαρμογής (MaterialApp.title + AppBar).
  static const String appTitle = 'Τιμές';

  // ─── Home / Stats (§2.1) ──────────────────────────────────────────────────
  /// Άδεια αποτελέσματα περιόδου — αντί για κενό γράφημα.
  static const String noPricesForPeriod =
      'Δεν υπάρχουν καταχωρημένες τιμές για αυτή την περίοδο';
  /// Κουμπί «Επανάληψη» στην κατάσταση error (ref.invalidate).
  static const String retryButton = 'Επανάληψη';

  // ─── Price entry (§2.2) ───────────────────────────────────────────────────
  /// Κουμπί αποθήκευσης ολόκληρης απόδειξης.
  static const String saveReceipt = 'Αποθήκευση Απόδειξης';
  /// Κουμπί προσθήκης γραμμής στο «καλάθι» της απόδειξης.
  static const String addReceiptLine = 'Προσθήκη γραμμής';
  /// Labels πεδίων φόρμας (header + unit/quantity/price section).
  static const String fieldDate = 'Ημερομηνία';
  static const String fieldSupplier = 'Προμηθευτής';
  static const String fieldQuantity = 'Ποσότητα';
  static const String fieldPrice = 'Τιμή';
}