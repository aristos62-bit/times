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
  /// Τίτλος κάρτας «Ανά προμηθευτή» (§2.1 · Φάση 5).
  static const String chartSupplierTitle = 'Ανά προμηθευτή';
  /// Τίτλος κάρτας «Ανά κατηγορία» (§2.1 · Φάση 5).
  static const String chartCategoryTitle = 'Ανά κατηγορία';
  /// Τίτλος κάρτας «Ανά υποκατηγορία» (§2.1 · 27-09-2026 — 5η πίτα,
  /// μεταξύ κατηγορίας και τμήματος).
  static const String chartSubCategoryTitle = 'Ανά υποκατηγορία';
  /// Τίτλος κάρτας «Ανά τμήμα» (§2.1 · 4 επίπεδα 27-09-2026 — αντικαθιστά
  /// την πίτα υποκατηγορίας).
  static const String chartItemGroupTitle = 'Ανά τμήμα';
  /// Τίτλος κάρτας Top-10 ειδών (§2.1 · Φάση 5).
  static const String chartTopItemsTitle = 'Top-10 είδη';
  /// Label περιόδου «Ημέρα» (per-chart selector, §2.1 · Φάση 5).
  static const String periodDay = 'Ημέρα';
  /// Label περιόδου «Εβδομάδα» (per-chart selector, §2.1 · Φάση 5).
  static const String periodWeek = 'Εβδομάδα';
  /// Label περιόδου «Μήνας» (per-chart selector, §2.1 · Φάση 5).
  static const String periodMonth = 'Μήνας';
  /// Label περιόδου «Έτος» (per-chart selector, §2.1 · Φάση 5).
  static const String periodYear = 'Έτος';
  /// Label περιόδου «Προσαρμοσμένο» (per-chart selector, §2.1 · Φάση 5).
  static const String periodCustom = 'Προσαρμοσμένο';
  /// Τίτλος «Προσαρμογή Οθόνης» (τελευταία γραμμή, §2.1 · Φάση 5).
  static const String homeCustomizationTitle = 'Προσαρμογή Οθόνης';
  /// Label φέτας «Λοιπά» (top-N + Λοιπά, §2.1:183 · Φάση 5).
  static const String othersSliceLabel = 'Λοιπά';
  /// Label γραμμής γενικού συνόλου κάρτας (άθροισμα φετών, §2.1 · 26-09-2026).
  static const String chartTotalLabel = 'Σύνολο';
  /// Tooltip/semantics του βέλους «πάνω» στην Προσαρμογή Οθόνης (§2.1 · Βήμα 5).
  static const String chartMoveUp = 'Μετακίνηση πάνω';
  /// Tooltip/semantics του βέλους «κάτω» στην Προσαρμογή Οθόνης (§2.1 · Βήμα 5).
  static const String chartMoveDown = 'Μετακίνηση κάτω';
  /// Τίτλος κάρτας «Πορεία τιμής» (§2.1 · 28-09-2026 — 6ο γράφημα, γραμμή).
  static const String chartItemTrendTitle = 'Πορεία τιμής';
  /// Hint αναζήτησης είδους στην κάρτα πορείας (§2.1 · 28-09-2026).
  static const String trendItemSearchHint = 'Αναζήτηση είδους';
  /// Idle κάρτας πορείας — κανένα είδος επιλεγμένο (όχι σφάλμα, όχι DB access).
  static const String trendNoItemSelected =
      'Επιλέξτε είδος για προβολή πορείας';
  /// Μονάδα άξονα Υ πορείας (καθαρή €/μονάδα, Δ-stat §3).
  static const String trendAxisUnit = '€/μονάδα';
  /// Label dropdown μετρικής κάρτας Top-10 (§2.1 · 29-09-2026, a11y §1.6).
  static const String topItemsMetricLabel = 'Μέτρηση';
  /// Επιλογές μετρικής Top-10 (§2.1 · 29-09-2026 — σταθερές 4, Q1).
  static const String topItemsMetricPieces = 'Τεμ';
  static const String topItemsMetricKilos = 'Κιλ';
  static const String topItemsMetricLiters = 'Λιτ';

  // ─── Price entry (§2.2) ───────────────────────────────────────────────────
  /// Τίτλος AppBar στη σελίδα εισαγωγής τιμών.
  static const String titlePriceEntry = 'Εισαγωγή Τιμών';
  /// Κουμπί αποθήκευσης ολόκληρης απόδειξης.
  static const String saveReceipt = 'Αποθήκευση Απόδειξης';
  /// Κουμπί ενημέρωσης απόδειξης σε edit mode (Φάση Α · 24-09-2026).
  static const String updateReceipt = 'Ενημέρωση Απόδειξης';
  /// Κουμπί προσθήκης γραμμής στο «καλάθι» της απόδειξης.
  static const String addReceiptLine = 'Προσθήκη γραμμής';
  /// Labels πεδίων φόρμας (header + unit/quantity/price section).
  static const String fieldDate = 'Ημερομηνία';
  static const String fieldSupplier = 'Προμηθευτής';
  static const String fieldQuantity = 'Ποσότητα';
  static const String fieldPrice = 'Τιμή';
  /// Label του πεδίου έκπτωσης γραμμής (ανά μονάδα, € — §2.2).
  /// Κενό ≡ καμία έκπτωση.
  static const String fieldDiscount = 'Έκπτωση';
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
  /// Label της inline επιλογής «+» για δημιουργία νέου τμήματος — το query
  /// αποδίδεται δυναμικά δίπλα («Νέο τμήμα "x"», 27-09-2026).
  static const String addNewItemGroup = 'Νέο τμήμα';
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
  /// Label πεδίου τμήματος (ορατό όνομα UI του ItemGroup — «Τμήμα»).
  static const String fieldItemGroup = 'Τμήμα';
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

  // ─── Items section (§2.3 · CRUD ειδών) ───────────────────────────────────
  /// Τίτλος του section «Είδη» στη σελίδα ρυθμίσεων (§2.3).
  static const String titleItemsSection = 'Είδη';
  /// Κενή κατάσταση αναζήτησης ειδών (§2.3 — πριν πληκτρολογήσει ο χρήστης).
  static const String itemsEmpty = 'Δεν υπάρχουν είδη ακόμα';

  // ─── Receipts section (§2.3 · Φάση Β 24-09-2026) ───────────────────────────
  /// Τίτλος του section «Αποδείξεις» στη σελίδα ρυθμίσεων (§2.3).
  static const String titleReceiptsSection = 'Αποδείξεις';
  /// Label κουμπιού καθαρισμού φίλτρου ημέρας — δείχνει όλες (§2.3 · Φάση Β).
  /// Χρησιμοποιείται και ως subtitle όταν δεν υπάρχει φίλτρο (μία τιμή,
  /// δύο χρήσεις — SPoT).
  static const String clearReceiptFilter = 'Όλες';
  /// Κενή κατάσταση φιλτραρισμένης ημέρας — καμία απόδειξη εκείνη την ημέρα.
  static const String noReceiptsForDay =
      'Δεν υπάρχουν αποδείξεις αυτή την ημέρα';

  // ─── Statistics section (§2.3 · 28-09-2026 + μενού 29-09-2026) ────────────
  /// Τίτλος του section «Στατιστικά» στη σελίδα ρυθμίσεων (§2.3).
  static const String titleStatisticsSection = 'Στατιστικά';
  /// Τίτλος 1ης ανάλυσης «Ιστορικό αγορών είδους» (μενού + detail §2.3).
  static const String statsLedgerTitle = 'Ιστορικό αγορών είδους';
  /// Περιγραφή 1ης ανάλυσης στο μενού (§2.3 · 29-09-2026).
  static const String statsLedgerDescription =
      'Αναλυτική καρτέλα αγορών είδους με εξαγωγή Excel/PDF';
  /// Label κουμπιού επιστροφής από ανάλυση στο μενού (§2.3 · 29-09-2026).
  static const String statsBackAction = 'Πίσω';
  /// Headers στηλών καρτέλας είδους (§2.3 · 1η ανάλυση).
  static const String statsColumnDate = 'Ημερομηνία';
  static const String statsColumnReceipt = 'Απόδειξη';
  static const String statsColumnSupplier = 'Προμηθευτής';
  /// Header στήλης κατηγορίας (2η ανάλυση §2.3 · 29-09-2026).
  static const String statsColumnCategory = 'Κατηγορία';
  static const String statsColumnQuantity = 'Ποσότητα';
  static const String statsColumnPrice = 'Τιμή';
  static const String statsColumnDiscount = 'Έκπτωση';
  static const String statsColumnNet = 'Καθαρή';
  /// Label κουμπιού εξαγωγής Excel (§2.3 · 1η ανάλυση).
  static const String statsExportExcelAction = 'Εξαγωγή Excel';
  /// Label κουμπιού εξαγωγής PDF (§2.3 · 1η ανάλυση).
  static const String statsExportPdfAction = 'Εξαγωγή PDF';
  /// Label γραμμής συνόλων καρτέλας (άθροισμα καθαρών, §2.3 · Q4).
  static const String statsTotalsLabel = 'Σύνολο';
  /// Πρόθεμα γενικού συνόλου ομαδοποιημένης αναφοράς (§2.3 · 3η ανάλυση).
  static const String statsGrandTotal = 'ΓΕΝΙΚΟ';
  /// Τίτλος 2ης ανάλυσης «Συνολικές αγορές» (μενού + detail §2.3).
  static const String statsPurchasesTitle = 'Συνολικές αγορές';
  /// Περιγραφή 2ης ανάλυσης στο μενού (§2.3 · 29-09-2026).
  static const String statsPurchasesDescription =
      'Συγκεντρωτικές αγορές περιόδου με ταξινόμηση και εξαγωγή';
  /// Labels ταξινόμησης αγορών (§2.3 · 2η ανάλυση).
  static const String statsSortLabel = 'Ταξινόμηση';
  /// Label dropdown ομαδοποίησης (§2.3 · 3η ανάλυση).
  static const String statsGroupLabel = 'Ομαδοποίηση';
  /// Hints φίλτρου καταλόγου (§2.3 · κενό = Όλα, Q1).
  static const String statsFilterAllCategories = 'Όλες οι κατηγορίες';
  static const String statsFilterAllSubCategories = 'Όλες οι υποκατηγορίες';
  static const String statsFilterAllItemGroups = 'Όλα τα τμήματα';
  /// Τίτλος 3ης ανάλυσης «Ομαδοποιημένη αναφορά» (μενού + detail §2.3).
  static const String statsGroupedTitle = 'Ομαδοποιημένη αναφορά';
  /// Περιγραφή 3ης ανάλυσης στο μενού (§2.3 · 29-09-2026).
  static const String statsGroupedDescription =
      'Σύνολα ανά κατηγορία, προμηθευτή ή ημέρα με προεπισκόπηση';
  /// Label κουμπιού προεπισκόπησης (§2.3 · 3η ανάλυση).
  static const String statsPreviewAction = 'Προεπισκόπηση';
  /// Labels ομαδοποίησης (§2.3 · 3η ανάλυση).
  static const String statsGroupCategory = 'Κατηγορία';
  static const String statsGroupSupplier = 'Προμηθευτής';
  static const String statsGroupDay = 'Ημέρα';
  static const String statsGroupMonth = 'Μήνας';
  static const String statsSortDateAsc = 'Ημερομηνία (παλιές → νέες)';
  static const String statsSortDateDesc = 'Ημερομηνία (νέες → παλιές)';
  static const String statsSortSupplier = 'Προμηθευτής';
  static const String statsSortCategory = 'Κατηγορία';

  // ─── Backup section (§2.3 · Φάση 4 Βήμα 5) ─────────────────────────────────
  /// Τίτλος του section «Αντίγραφα ασφαλείας» στη σελίδα ρυθμίσεων (§2.3).
  static const String titleBackupSection = 'Αντίγραφα ασφαλείας';
  /// Label κουμπιού εξαγωγής αντιγράφου (§2.3 · Βήμα 5).
  static const String backupExportAction = 'Εξαγωγή αντιγράφου';
  /// Label κουμπιού επαναφοράς αντιγράφου (§2.3 · Βήμα 5).
  static const String backupRestoreAction = 'Επαναφορά αντιγράφου';
}