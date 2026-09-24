/// SPoT: Κείμενα εμφάνισης (labels, τίτλοι, placeholders) — «τι βλέπει ο χρήστης».
/// Μόνο ΣΤΑΤΙΚΑ κείμενα UI. Δυναμικά/εμφωλευμένα μηνύματα ροής (SnackBar,
/// confirm dialogs) → app_messages.dart · μηνύματα σφάλματος → app_errors.dart.
library;

/// Abstract SPoT class — μόνο σταθερές, δεν instantiate (pattern AppConstants).
abstract final class AppStrings {
  // ─── App identity (§0 DESIGN) ─────────────────────────────────────────────
  /// Εμφανιζόμενο όνομα εφαρμογής (MaterialApp.title + AppBar).
  static const String appTitle = 'Τιμές';

  // ─── Navigation / App shell (§2.0 · Φάση 3 Βήμα 1) ───────────────────────
  /// Label destination "Αρχική" στο NavigationBar.
  static const String navHome = 'Αρχική';
  /// Label destination "Εισαγωγή Τιμών" στο NavigationBar.
  static const String navPriceEntry = 'Εισαγωγή';
  /// Label destination "Ρυθμίσεις" στο NavigationBar.
  static const String navSettings = 'Ρυθμίσεις';

  // ─── Home / Stats (§2.1) ──────────────────────────────────────────────────
  /// Άδεια αποτελέσματα περιόδου — αντί για κενό γράφημα.
  static const String noPricesForPeriod =
      'Δεν υπάρχουν καταχωρημένες τιμές για αυτή την περίοδο';
  /// Κουμπί «Επανάληψη» στην κατάσταση error (ref.invalidate).
  static const String retryButton = 'Επανάληψη';
  /// Placeholder text στη σελίδα στατιστικών (μέχρι Φάση 5).
  static const String statsComingSoon = 'Τα στατιστικά θα εμφανιστούν σύντομα';

  // ─── Price entry (§2.2) ───────────────────────────────────────────────────
  /// Τίτλος AppBar στη σελίδα εισαγωγής τιμών.
  static const String titlePriceEntry = 'Εισαγωγή Τιμών';
  /// Κουμπί αποθήκευσης ολόκληρης απόδειξης.
  static const String saveReceipt = 'Αποθήκευση Απόδειξης';
  /// Κουμπί προσθήκης γραμμής στο «καλάθι» της απόδειξης.
  static const String addReceiptLine = 'Προσθήκη γραμμής';
  /// Labels πεδίων φόρμας (header + unit/quantity/price section).
  static const String fieldDate = 'Ημερομηνία';
  static const String fieldSupplier = 'Προμηθευτής';
  static const String fieldQuantity = 'Ποσότητα';
  static const String fieldPrice = 'Τιμή';
  /// Label του διακόπτη «Συνολική τιμή» στη φόρμα γραμμής (§2.2 · 24-09-2026):
  /// ΟΝ = το πεδίο Τιμή είναι το σύνολο της ποσότητας (π.χ. 350 γρ = 12 €)·
  /// OFF (default) = τιμή μονάδας. Ισχύει για όλες τις μονάδες.
  static const String priceTotalMode = 'Συνολική τιμή';
  /// Inline λέξη για το σύνολο γραμμής στο «καλάθι» (§2.2 · 24-09-2026):
  /// εμφανίζεται ΜΟΝΟ σε γραμμές συνολικής τιμής
  /// («0,35 κιλ · 34,29 € (σύνολο 12,00 €)»).
  static const String lineTotalLabel = 'σύνολο';
  /// Label του πεδίου μονάδας (Unit dropdown, §2.2 · Βήμα 5γ). Το DESIGN δεν
  /// ορίζει ρητό label (απόφαση Φάσης 0) — «Μονάδα», συνεπές με τα υπόλοιπα
  /// field labels.
  static const String fieldUnit = 'Μονάδα';
  /// Hint στο πεδίο αναζήτησης μονάδας (Unit dropdown, §2.4 · Βήμα 5γ).
  static const String unitSearchHint = 'Αναζήτηση μονάδας';
  /// Σύμβολο νομίσματος ως suffix στο πεδίο τιμής (§2.2 · Βήμα 5γ).
  static const String currencySymbol = '€';
  /// Τίτλος της λίστας γραμμών («καλάθι») της τρέχουσας απόδειξης (§2.2).
  static const String draftLinesTitle = 'Γραμμές απόδειξης';
  /// Κενή κατάσταση της λίστας γραμμών — καμία γραμμή ακόμα (§2.2).
  static const String draftLinesEmpty = 'Δεν υπάρχουν γραμμές ακόμα';
  /// Τίτλος της read-only λίστας πρόσφατων αποδείξεων (§2.2 · Βήμα 7).
  static const String recentReceiptsTitle = 'Πρόσφατες αποδείξεις';
  /// Κενή κατάσταση της λίστας πρόσφατων αποδείξεων (§2.2 · Βήμα 7).
  static const String recentReceiptsEmpty =
      'Δεν υπάρχουν αποθηκευμένες αποδείξεις ακόμα';
  /// Tooltip/semantics του κουμπιού διαγραφής γραμμής από το «καλάθι» (§2.2).
  static const String removeDraftLine = 'Αφαίρεση γραμμής';
  /// Inline ειδοποίηση περικοπής: δεκαδική ποσότητα σε μονάδα χωρίς κλάσματα
  /// (π.χ. «2,5 τεμ» → «2») κόβεται αυτόματα στο ακέραιο μέρος (§2.2:218).
  static const String quantityTruncatedForUnit =
      'Η ποσότητα κόπηκε σε ακέραια (η μονάδα δεν δέχεται δεκαδικά)';
  /// Hint στο πεδίο αναζήτησης προμηθευτή (SearchableDropdownField, §2.4).
  static const String supplierSearchHint = 'Αναζήτηση προμηθευτή';
  /// Label της inline επιλογής «+» για δημιουργία νέου προμηθευτή — το
  /// πληκτρολογημένο query αποδίδεται δυναμικά δίπλα («Νέος προμηθευτής "x"»).
  static const String addNewSupplier = 'Νέος προμηθευτής';
  /// Hint στο πεδίο αναζήτησης είδους (ItemSearchField, §2.4 · Βήμα 4).
  static const String itemSearchHint = 'Αναζήτηση είδους';
  /// Μήνυμα κατάστασης idle στο ItemSearchField — πριν πληκτρολογήσει ο
  /// χρήστης (§2.4 · Βήμα 4, inline panel).
  static const String itemSearchIdle = 'Πληκτρολογήστε για αναζήτηση είδους';
  /// Label της inline επιλογής «+» για δημιουργία νέας κατηγορίας — το query
  /// αποδίδεται δυναμικά δίπλα («Νέα κατηγορία "x"», Βήμα 4).
  static const String addNewCategory = 'Νέα κατηγορία';
  /// Label της inline επιλογής «+» για δημιουργία νέας υποκατηγορίας — το
  /// query αποδίδεται δυναμικά δίπλα («Νέα υποκατηγορία "x"», Βήμα 4).
  static const String addNewSubCategory = 'Νέα υποκατηγορία';
  /// Label της inline επιλογής «+» για δημιουργία νέου είδους — το query
  /// αποδίδεται δυναμικά δίπλα («Νέο είδος "x"», Βήμα 4).
  static const String addNewItem = 'Νέο είδος';
  /// Label της γραμμής «Αλλαγή» στο banner επιλεγμένου είδους (Βήμα 4).
  static const String changeItem = 'Αλλαγή';
  /// Label κουμπιού επανάληψης αναζήτησης σε σφάλμα (ItemSearchField, Βήμα 4).
  static const String itemSearchRetry = 'Δοκιμή ξανά';
  /// Labels πεδίων στο popup δημιουργίας νέου είδους (dialog, Βήμα 4).
  static const String fieldCategory = 'Κατηγορία';
  static const String fieldSubCategory = 'Υποκατηγορία';
  static const String fieldItemName = 'Όνομα είδους';
  /// Τίτλος του popup δημιουργίας νέου είδους (Βήμα 4).
  static const String newItemDialogTitle = 'Νέο είδος';
  /// Κουμπί μετάβασης στο επόμενο βήμα του wizard dialog (Βήμα 4).
  static const String newItemNextStep = 'Επόμενο';
  /// Κουμπί αποθήκευσης στο popup νέου είδους (Βήμα 4).
  static const String newItemSave = 'Προσθήκη';

  // ─── Settings (§2.3) ──────────────────────────────────────────────────────
  /// Τίτλος AppBar στη σελίδα ρυθμίσεων.
  static const String titleSettings = 'Ρυθμίσεις';
  /// Τίτλος του section «Θέμα» στη σελίδα ρυθμίσεων (§2.3 · Φάση 4 Βήμα 1).
  static const String titleThemeSection = 'Θέμα';
  /// Επιλογή θέματος: Φωτεινό (ThemeMode.light, §2.3:270).
  static const String themeModeLight = 'Φωτεινό';
  /// Επιλογή θέματος: Σκοτεινό (ThemeMode.dark, §2.3:270).
  static const String themeModeDark = 'Σκοτεινό';
  /// Επιλογή θέματος: Αυτόματο (ThemeMode.system, §2.3:270).
  static const String themeModeSystem = 'Αυτόματο';

  // ─── Categories section (§2.3 · Φάση 4 Βήμα 4) ──────────────────────────
  /// Τίτλος του section «Κατηγορίες» στη σελίδα ρυθμίσεων (§2.3 · Βήμα 4).
  static const String titleCategoriesSection = 'Κατηγορίες';
  /// Κενή κατάσταση του δέντρου κατηγοριών (§2.3 · Βήμα 4).
  static const String categoriesEmpty = 'Δεν υπάρχουν κατηγορίες ακόμα';
  /// Tooltip/semantics του κουμπιού επεξεργασίας κατηγορίας/υποκατηγορίας
  /// (§2.3 · Βήμα 4).
  static const String editAction = 'Επεξεργασία';
  /// Tooltip/semantics του κουμπιού διαγραφής κατηγορίας/υποκατηγορίας
  /// (§2.3 · Βήμα 4).
  static const String deleteAction = 'Διαγραφή';
  /// Tooltip/semantics του κουμπιού ανανέωσης των ελέγχων διαγραφής
  /// (§2.3 · Βήμα 4 — οι `canDelete*` είναι one-shot, μπαγιατεύουν).
  static const String refreshAction = 'Ανανέωση';
  /// Label κουμπιού αποθήκευσης σε dialogs επεξεργασίας (§2.3 · Βήμα 4).
  static const String saveAction = 'Αποθήκευση';

  // ─── Suppliers section (§2.3 · CRUD προμηθευτών 24-09-2026) ───────────────
  /// Τίτλος του section «Προμηθευτές» στη σελίδα ρυθμίσεων (§2.3).
  static const String titleSuppliersSection = 'Προμηθευτές';
  /// Κενή κατάσταση της λίστας προμηθευτών (§2.3).
  static const String suppliersEmpty = 'Δεν υπάρχουν προμηθευτές ακόμα';
}