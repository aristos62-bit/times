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

  // ─── Dialog (§1.4) ─────────────────────────────────────────────────────────
  // Μέγιστο πλάτος popup dialogs (π.χ. NewItemFlowDialog) — responsive:
  // max-width + scroll (SingleChildScrollView), όχι fixed ύψος (§1.4).
  static const double dialogMaxWidth = 440.0;

  // ─── Preloader indicators ──────────────────────────────────────────────────
  // Μέγεθος spinner στο «+» του SearchableDropdownField (overlay).
  static const double smallSpinnerSize = 16.0;
  // Μέγεθος spinner στο κουμπί «Προσθήκη» του NewItemFlowDialog.
  static const double dialogSpinnerSize = 18.0;
  // Κοινό πάχος γραμμής CircularProgressIndicator (2+ σημεία, §1.1).
  static const double spinnerStrokeWidth = 2.0;

  // ─── Lists (§1.4) ──────────────────────────────────────────────────────────
  // Ύψος διαχωριστικών γραμμών σε λίστες αποτελεσμάτων.
  static const double listDividerHeight = 1.0;

  // ─── Search / Autocomplete (§2.2 DESIGN) ──────────────────────────────────
  // Debounce πριν την αναζήτηση στη βάση.
  static const int searchDebounceMillis = 250;

  // Ελάχιστοι χαρακτήρες για να πυροδοτηθεί η αναζήτηση («ανά γράμμα» →
  // το 1 γράμμα ξεκινάει άμεσα).
  static const int searchMinChars = 1;

  // Πάνω όριο αποτελεσμάτων που εμφανίζονται — αποτρέπει overflow της λίστας
  // όταν το searchMinChars=1 επιστρέφει πολλά αποτελέσματα (§1.4).
  static const int searchResultsLimit = 15;

  // Μέγιστο ύψος του overlay λίστας στο SearchableDropdownField (§2.4).
  // Κάτω από αυτό η λίστα γίνεται scrollable — αποτρέπει overflow σε
  // μικρές οθόνες με πολλά αποτελέσματα (§1.4, κανόνας «όχι fixed heights
  // σε λίστες/φόρμες»: εδώ είναι όριο MAX, όχι σταθερό ύψος).
  static const double searchDropdownMaxHeight = 320.0;

  // ─── Validation όρια ───────────────────────────────────────────────────────
  // ΑΠΟΚΛΕΙΣΤΙΚΟ όριο — όχι αποδεκτή τιμή. Δεκτό μόνο price > validationMinPrice.
  // Η σύγκριση γίνεται σε ΛΕΠΤΑ (priceCents, §3) — ίδια μονάδα με την
  // αποθήκευση της τιμής, όχι σε ευρώ.
  static const double validationMinPrice = 0.0;

  // ΑΠΟΚΛΕΙΣΤΙΚΟ όριο — όχι αποδεκτή τιμή. Δεκτό μόνο quantity > validationMinQuantity.
  static const double validationMinQuantity = 0.0;

  // Μέγιστο μήκος ονόματος για Είδος/Κατηγορία/Υποκατηγορία/Προμηθευτή.
  static const int maxItemNameLength = 100;

  // Μέγιστες γραμμές του inline μηνύματος σφάλματος πεδίου (errorText) —
  // safety net αποφυγής κοπής/overflow σε στενές οθόνες ή μεγάλα fonts
  // (§1.4 DESIGN). Ίδιο σκεπτικό με το maxFeedbackLines των SnackBar.
  static const int fieldErrorMaxLines = 3;

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

  // ─── Numeric / Limits (Φάση 3 Βήμα 5) ─────────────────────────────────────
  // Μέγιστο μήκος κειμένου (χαρακτήρες) του πεδίου τιμής (€). Είναι όριο
  // ΕΙΣΟΔΟΥ (input), όχι αποδεκτή τιμή — το πραγματικό ανώτατο όριο θέτει
  // το maxPriceCents (αναλύεται στο parseCents). Καλύπτει π.χ. «9999999,99».
  static const int priceMaxLength = 10;

  // Μέγιστο μήκος κειμένου (χαρακτήρες) του πεδίου ποσότητας — όριο ΕΙΣΟΔΟΥ.
  // Το πραγματικό ανώτατο όριο θέτει το maxQuantity (στο parseQuantity).
  // Καλύπτει π.χ. «1000000,000».
  static const int quantityMaxLength = 11;

  // ΑΝΩΤΑΤΟ όριο τιμής σε λεπτά (cents) — όχι αποδεκτή τιμή μεταγενέστερη.
  // «€99.999,99». Το parseCents επιστρέφει null αν το κείμενο το ξεπεράσει.
  static const int maxPriceCents = 9999999;

  // ΑΝΩΤΑΤΟ όριο ποσότητας (μονάδες) — όχι αποδεκτή τιμή μεταγενέστερη.
  // Το parseQuantity επιστρέφει null αν το κείμενο το ξεπεράσει.
  static const double maxQuantity = 1000000.0;

  // ─── Date picker (§2.2 / Φάση 3 Βήμα 2) ───────────────────────────────────
  // Ελάχιστο έτος που επιτρέπει ο showDatePicker (firstDate) — όρια φόρμας
  // απόδειξης, τίποτα hardcoded (§1.1).
  static const int datePickerFirstYear = 2000;

  // Μέγιστο έτος (lastDate) — ο χρήστης δεν εισάγει ημερομηνία εκτός
  // λογικού εύρους αποδείξεων (read-only field, μόνο picker).
  static const int datePickerLastYear = 2100;

  // ─── Lists / Limits ────────────────────────────────────────────────────────
  // Πλήθος τελευταίων αποδείξεων στη λίστα PriceEntry (Φάση 3).
  static const int recentReceiptsLimit = 20;

  // Πλήθος αποδείξεων στη «Διαχείριση αποδείξεων» (§2.3 · Φάση Β): η λίστα
  // μεγαλώνει απεριόριστα στη βάση, οπότε το άφιλτρο προβάλλει τις Ν
  // νεότερες (τεκμηριωμένο όριο προσωπικής χρήσης — όχι απόκρυψη σφάλματος).
  static const int manageReceiptsLimit = 100;

  // Μέγιστες γραμμές ειδών ανά απόδειξη (καλάθι).
  static const int maxReceiptLines = 100;

  // ─── Timing / UX ───────────────────────────────────────────────────────────
  // Διάρκεια εμφάνισης SnackBar μηνυμάτων επιβεβαίωσης.
  static const int snackBarDurationSeconds = 4;

  // Timeout του διαγνωστικού probe `SELECT 1` στο `closeSafely` (restore):
  // ο executor απαντά σε ms — λήξη = μπλοκαρισμένος (transaction/isolate).
  static const int restoreProbeTimeoutSeconds = 3;

  // Χάρη κλεισίματος βάσης στο restore: το drift `close()` μπορεί να
  // κρεμάσει (αποδεδειγμένα σε συσκευή, 27-09-2026) — λήξη = log + συνέχεια
  // στο replace (αντί παγωμένη εφαρμογή).
  static const int restoreCloseTimeoutSeconds = 5;

  // Μέγιστες γραμμές SnackBar μηνύματος — safety net αποφυγής overflow (§1.4
  // DESIGN) σε στενές οθόνες / μεγάλα fonts / ασυνήθιστα μακρά μηνύματα.
  static const int maxFeedbackLines = 3;

  // Περιοδικότητα ελέγχου αλλαγής ημέρας του `todayProvider` (§2.1).
  // Day-gate: ειδοποιεί ΜΟΝΟ σε αλλαγή ημέρας — το κόστος είναι μία
  // σύγκριση DateTime ανά tick (κανένα IO/DB).
  static const int clockCheckSeconds = 60;

  // ─── Theme (§2.3 DESIGN · Φάση 4 Βήμα 1) ─────────────────────────────────
  // Key της SharedPreferences όπου αποθηκεύεται το επιλεγμένο ThemeMode
  // (Light/Dark/Auto). Οι αποθηκευμένες τιμές είναι οι κωδικοί του enum
  // (mode.name) — SEE settings_repository_impl (SPoT mapping, §2.3:270).
  static const String themeModeKey = 'theme_mode';

  // ─── Κλείδωμα εφαρμογής (§2.3 · 30-09-2026) ────────────────────────────
  // Key της SharedPreferences για το κλείδωμα (bool, pattern themeModeKey).
  static const String appLockEnabledKey = 'app_lock_enabled';

  // Περίοδος χάριτος σε δευτερόλεπτα: επιστροφή από background μέσα σε
  // αυτό το διάστημα ΔΕΝ ζητά ξεκλείδωμα (Q2).
  static const int appLockGraceSeconds = 30;

  // Timeout ταυτοποίησης σε δευτερόλεπτα (01-10): native auth που δεν
  // επιστρέφει ποτέ → `TimeoutException` → ορατό σφάλμα + retry (αντί
  // για κενό overlay). Συντηρητικό για αργές συσκευές.
  static const int appLockAuthTimeoutSeconds = 60;

  // Σταθερό ύψος περιοχής retry-κουμπιού (§1.4 — όχι layout jump όταν
  // εμφανίζεται/κρύβεται το κουμπί).
  static const double appLockButtonHeight = 48.0;

  // Μέγεθος icon κλειδαριάς στην οθόνη ξεκλειδώματος.
  static const double appLockIconSize = 64.0;

  // ─── Charts (§2.1 DESIGN · Φάση 5 Βήμα 1) ─────────────────────────────────
  // Πλήθος φετών πίτας (top-N + «Λοιπά», §2.1:183) — suppliers/κατηγορίες.
  static const int pieMaxSlices = 8;

  // Πλήθος ειδών στην πίτα Top-10 (top-N + «Λοιπά», §2.1:183).
  static const int topItemsLimit = 10;

  // Key της SharedPreferences για το persisted chart config
  // (ορατότητα/περίοδος/σειρά ανά γράφημα, §2.1 · pattern themeModeKey).
  static const String homeChartConfigKey = 'home_chart_config';

  // ─── Item trend (§2.1 · 28-09-2026) ──────────────────────────────────────
  // Ύψος γραφήματος πορείας τιμής (συμμετρικό του `pieChartHeight`).
  static const double trendChartHeight = 220.0;

  // Key της SharedPreferences για το επιλεγμένο είδος πορείας (itemId,
  // pattern `themeModeKey` — persist επιλογής, §2.1 Q5).
  static const String trendSelectedItemKey = 'home_trend_item_id';

  // ─── Top-10 metric (§2.1 · 29-09-2026) ───────────────────────────────────
  // Key μετρικής κάρτας Top-10 (τιμή `.name` του enum, pattern themeModeKey).
  static const String topItemsMetricKey = 'top_items_metric';

  // Safety cap σημείων γραμμής πορείας — πάνω από αυτό κρατιούνται τα
  // νεότερα (τεκμηριωμένο όριο προσωπικής χρήσης, §2.1 Q4).
  static const int trendMaxPoints = 200;

  // ─── Statistics (§2.3 · 28-09-2026) ──────────────────────────────────────
  // Pattern ονομασίας αρχείων εξαγωγής καρτέλας (ίδιο template με το backup —
  // `backupFileNamePattern`, άλλη αρχή· η επέκταση μπαίνει από τον καλούντα).
  static const String statsFileNamePattern = 'times_stats_yyyyMMdd_HHmmss';

  // ─── PDF export (§2.3 · 01-10): raw doubles προβολής (όχι Material
  // textTheme — το `pdf` πακέτο θέλει σκέτα νούμερα· εξαίρεση από τον κανόνα
  // «typography → app_theme», pure-Dart χωρίς material import στο domain).
  // Μεγέθη γραμματοσειράς ανά ρόλο (SPoT ανά χρήση, §1.1).
  static const double pdfTitleFontSize = 14.0;
  static const double pdfSectionFontSize = 11.0;
  static const double pdfBodyFontSize = 10.0;
  static const double pdfPageNoFontSize = 9.0;

  // Paddings PDF ανά ρόλο (SPoT ανά χρήση, §1.1 — doubles μόνο, το
  // `pw.EdgeInsets` χτίζεται στον καλούντα).
  static const double pdfHeaderPaddingBottom = 8.0;
  static const double pdfSectionPaddingTop = 10.0;
  static const double pdfSectionPaddingBottom = 4.0;
  static const double pdfSubtotalPaddingTop = 2.0;
  static const double pdfSubtotalPaddingBottom = 6.0;
  static const double pdfCellPadding = 4.0;

  // ─── Εξαγωγή καταλόγου (§2.3 · 30-09-2026) ───────────────────────────────
  // Pattern ονομασίας αρχείου καταλόγου (ίδιο template, άλλη αρχή —
  // σκόπιμα χωριστή const, §1.1: SPoT ανά χρήση).
  static const String catalogFileNamePattern = 'times_catalog_yyyyMMdd_HHmmss';

  // Safety cap γραμμών καρτέλας (χωριστό από `trendMaxPoints` — άλλο UI,
  // §1.1: SPoT ανά χρήση, όχι κοινόχρηστος αριθμός).
  static const int statsTableMaxRows = 200;

  // ─── Item trend painter (§2.1 · 28-09-2026) ───────────────────────────────
  // Αριστερό περιθώριο ετικετών Υ + κάτω περιθώριο ετικετών Χ (fixed px —
  // χώρος κειμένου, όχι layout περιεχομένου).
  static const double trendAxisGutterLeft = 56.0;
  static const double trendAxisGutterBottom = 22.0;

  // Πάχος γραμμής πορείας + ακτίνα dots.
  static const double trendLineWidth = 2.0;
  static const double trendDotRadius = 3.0;

  // Ύψος κάρτας πίτας (auto-size πλάτος μέσω LayoutBuilder, §1.4).
  static const double pieChartHeight = 220.0;

  // Κάτω από αυτό το πλάτος η πίτα αντικαθίσταται από fallback πίνακα
  // (§1.4 + §2.1:184 — όχι overflow/μικροσκοπική πίτα). Fix 26-09: 360→300 —
  // η κάρτα έχει οριζόντιο padding 16, οπότε σε κινητό 320px μένουν 304:
  // με 360 έβλεπε ΠΑΝΤΑ πίνακα, ποτέ πίτα.
  static const double pieFallbackMaxWidth = 300.0;

  // ─── Pie 3D-εφέ (§2.1 · Φάση 5 Βήμα 4) ───────────────────────────────────
  // Σχετικό πάχος φέτας (κλάσμα του ύψους): πλευρά 3D = depth κάτω από την
  // κεκλιμένη έλλειψη (custom `Pie3dPainter` — το fl_chart δεν έχει 3D).
  static const double pieDepthRatio = 0.12;

  // Κατακόρυφη συμπίεση της πίτας (κλάσμα του πλάτους): tilt-εφέ βάθους.
  static const double pieTiltRatio = 0.5;

  // ─── Backup (§2.3 DESIGN) ──────────────────────────────────────────────────
  // Pattern ονομασίας αρχείων backup — βλ. DESIGN.md §2.3.
  // Χρησιμοποιεί το πρότυπο ημερομηνίας (yyyy=έτος, MM=μήνας, dd=ημέρα,
  // HH=ώρα, mm=λεπτά, ss=δευτερόλεπτα).
  static const String backupFileNamePattern = 'times_backup_yyyyMMdd_HHmmss';

  // Πλήθος auto-backups που κρατιούνται (retention 30-09-2026): κάθε
  // restore προσθέτει ένα `auto_<ts>.sqlite` — τα παλιότερα σβήνονται
  // μετά από επιτυχημένο restore (`pruneAutoBackups`, §2.3).
  static const int autoBackupRetentionCount = 5;
}
