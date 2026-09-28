/// SPoT: Προβολές αθροισμάτων γραφημάτων Κεντρικής — Φάση 5, Βήμα 2 (§2.1).
///
/// Κάθε record είναι **projection**, όχι οντότητα πίνακα: παράγεται
/// αποκλειστικά από το SQL aggregation του `ReceiptDao.watchTotals*`
/// (`SUM` του αποθηκευμένου `lineTotalCents` — SPoT: ReceiptLineDao, §3).
/// Ζουν στον ανοιχτό φάκελο `data/models` (§1.2) ως plain record typedefs —
/// χωρίς Freezed (pattern `ReceiptSummary`/`CategoryTreeNode`, Φάση 2 Βήμα 1).
///
/// Σlicing top-N + «Λοιπά» γίνεται στον provider Βήματος 3 πάνω στην πλήρη
/// ordered λίστα (ακριβές υπόλοιπο — η SQL δεν κάνει LIMIT, §2.1:183).
library;

/// Σύνολο προμηθευτή σε περίοδο (καθαρό, μετά έκπτωση §3).
typedef SupplierTotal = ({
  /// FK → Suppliers.id.
  int supplierId,

  /// Όνομα προμηθευτή (INNER JOIN — μόνο με πωλήσεις στην περίοδο).
  String supplierName,

  /// Συνολικό ποσό σε λεπτά (SUM lineTotalCents).
  int totalCents,
});

/// Σύνολο κατηγορίας σε περίοδο (καθαρό, μετά έκπτωση §3).
typedef CategoryTotal = ({
  /// FK → Categories.id.
  int categoryId,

  /// Όνομα κατηγορίας (INNER JOIN — μόνο με πωλήσεις στην περίοδο).
  String categoryName,

  /// Συνολικό ποσό σε λεπτά (SUM lineTotalCents).
  int totalCents,
});

/// Σύνολο υποκατηγορίας σε περίοδο (καθαρό, μετά έκπτωση §3).
typedef SubCategoryTotal = ({
  /// FK → SubCategories.id.
  int subCategoryId,

  /// Όνομα υποκατηγορίας (INNER JOIN — μόνο με πωλήσεις στην περίοδο).
  String subCategoryName,

  /// Συνολικό ποσό σε λεπτά (SUM lineTotalCents).
  int totalCents,
});

/// Σύνολο τμήματος σε περίοδο (καθαρό, μετά έκπτωση §3) — 4 επίπεδα.
typedef ItemGroupTotal = ({
  /// FK → ItemGroups.id.
  int itemGroupId,

  /// Όνομα τμήματος (INNER JOIN — μόνο με πωλήσεις στην περίοδο).
  String itemGroupName,

  /// Συνολικό ποσό σε λεπτά (SUM lineTotalCents).
  int totalCents,
});

/// Σύνολο είδους σε περίοδο (καθαρό, μετά έκπτωση §3) — για το Top-10.
typedef ItemTotal = ({
  /// FK → Items.id.
  int itemId,

  /// Όνομα είδους (INNER JOIN — μόνο με πωλήσεις στην περίοδο).
  String itemName,

  /// Συνολικό ποσό σε λεπτά (SUM lineTotalCents).
  int totalCents,
});

/// Παράμετρος-κλειδί των chart stream families (§2.1 · Φάση 5 Βήμα 3).
///
/// ΜΟΝΟ `from`/`to` (start-inclusive/end-exclusive, από τον
/// `resolvePeriodRange`): το `limit` ΔΕΝ μπαίνει στο κλειδί — εφαρμόζεται στο
/// slice (SPoT `pieMaxSlices`/`topItemsLimit`, Q1 Βήματος 2). Plain record —
/// value equality για το family cache (pattern `subCategorySearchProvider`
/// `({categoryId, query})`).
typedef ChartQuery = ({DateTime from, DateTime to});

/// Μία φέτα πίτας: έτοιμη για προβολή (§2.1 · Φάση 5 Βήμα 3).
///
/// Παράγεται από τον `toChartSlices` (top-N + συνθετικό «Λοιπά») — το UI
/// δείχνει `label` + `formatCents(totalCents)` (SPoT προβολή §2.1:176).
/// ΣΚΟΠΙΜΑ int-only (29-09-2026): γενίκευση σε `num` θα έσπαγε typedef +
/// πίτα + fallback + tests — οι ποσότητες έχουν δικό τους `ChartQtySlice`.
typedef ChartSlice = ({String label, int totalCents});

/// Μετρική κάρτας Top-10 (§2.1 · 29-09-2026 — σταθερές 4, Q1).
///
/// `euros` = σύνολα € (συμπεριφορά Φάσης 5, αμετάβλητη) · οι υπόλοιπες =
/// top ποσοτήτων ανά μονάδα (μία μονάδα ανά query — ποτέ ανάμειξη).
enum TopItemsMetric { euros, pieces, kilos, liters }

/// Μία φέτα ποσότητας: έτοιμη για προβολή (§2.1 · 29-09-2026).
///
/// Παράγεται από τον `toQtySlices` (top-N + συνθετικό «Λοιπά», exact
/// υπόλοιπο — mirror `toChartSlices` για doubles).
typedef ChartQtySlice = ({String label, double qty});

/// Σύνολο είδους σε ποσότητα (§2.1 · 29-09-2026) — projection του
/// `watchTopItemsByUnit` (SUM στρογγυλεμένο στα 3 δεκαδικά στη SQL).
typedef ItemQtyTotal = ({
  /// FK → Items.id.
  int itemId,

  /// Όνομα είδους (INNER JOIN — μόνο με κίνηση στην περίοδο).
  String itemName,

  /// Συνολική ποσότητα (στρογγυλεμένη §3-decimals).
  double qty,
});

/// Παράμετρος-κλειδί του qty stream family (§2.1 · 29-09-2026).
///
/// Plain record — value equality για το family cache (pattern `ChartQuery`).
typedef TopItemsQtyQuery = ({DateTime from, DateTime to, int unitId});

/// Σημείο πορείας τιμής είδους (§2.1 · 28-09-2026 — 6ο γράφημα, γραμμή).
///
/// Projection (όχι οντότητα): παράγεται από το `watchItemHistory` του
/// `ReceiptLineDao` (καθαρή μοναδιαία `price_cents − discount_cents`, Δ-stat
/// §3). Το `unitId` μένει στο point για το φίλτρο κλειδωμένης μονάδας
/// (Q2 — οι ξένες μονάδες μετριούνται, δεν σχεδιάζονται).
typedef ItemPricePoint = ({
  /// Ημερομηνία απόδειξης της γραμμής.
  DateTime date,

  /// Καθαρή τιμή μονάδας σε λεπτά (`priceCents − discountCents`, §3).
  int netPriceCents,

  /// Ποσότητα γραμμής (για διάκριση ίδιων ημερών / tooltip).
  double quantity,

  /// Μονάδα γραμμής (FK → Units.id) — φίλτρο κλειδωμένης μονάδας (Q2).
  int unitId,

  /// Όνομα προμηθευτή (INNER JOIN — fallback/tooltip).
  String supplierName,
});

/// Παράμετρος-κλειδί του trend stream family (§2.1 · 28-09-2026).
///
/// Το `unitId` μπαίνει στο κλειδί (αλλαγή μονάδας από Ρυθμίσεις = νέο
/// instance). Plain record — value equality για το family cache (pattern
/// `ChartQuery`).
typedef ItemTrendQuery = ({
  int itemId,
  int unitId,
  DateTime from,
  DateTime to,
});

/// Δεδομένα κάρτας πορείας: points κλειδωμένης μονάδας + πλήθος παλιών
/// γραμμών άλλης μονάδας (σημείωση Q2 — εκτός γραφήματος).
typedef ItemTrendData = ({
  List<ItemPricePoint> points,
  int otherUnitCount,
});

/// Παράμετρος-κλειδί του ledger stream family (§2.3 · 28-09-2026).
///
/// Plain record — value equality για το family cache (pattern `ChartQuery`,
/// με επιπλέον `itemId`).
typedef ItemLedgerQuery = ({int itemId, DateTime from, DateTime to});

/// Γραμμή καρτέλας είδους (§2.3 · 28-09-2026 — 1η στατιστική ανάλυση).
///
/// Projection (όχι οντότητα): παράγεται από το `watchItemLedger` του
/// `ReceiptLineDao` (stored τιμές §3 — ποτέ float). Η καθαρή είναι παράγωγη
/// display (`priceCents − discountCents`, mirror DAO όπως
/// `DraftReceiptLine.netTotalCents`).
typedef ItemLedgerRow = ({
  /// AUTOINCREMENT id απόδειξης = αριθμός απόδειξης (§3).
  int receiptId,

  /// Ημερομηνία απόδειξης.
  DateTime date,

  /// Όνομα προμηθευτή (INNER JOIN).
  String supplierName,

  /// Ποσότητα γραμμής (REAL §3).
  double quantity,

  /// Συντομογραφία μονάδας γραμμής (JOIN units — προβολή «0,456 κιλ»).
  String unitAbbreviation,

  /// Τιμή μονάδας σε λεπτά (μικτή, §3).
  int priceCents,

  /// Έκπτωση μονάδας σε λεπτά (0 = καμία, §2.2).
  int discountCents,
});

/// Ταξινόμηση αγορών (§2.3 · 2η ανάλυση «Συνολικές αγορές»).
///
/// Εφαρμόζεται στο SQL (precedent totals §2.1) με tiebreak ημερομηνία/id
/// (ντετερμινιστική σειρά — §2.1:183). default: `dateAsc` (παλιές → νέες).
enum PurchasesSort { dateAsc, dateDesc, supplier, category }

/// Γραμμή συγκεντρωτικών αγορών (§2.3 · 2η ανάλυση).
///
/// Projection: `watchPeriodPurchases` (stored §3). Η καθαρή παράγωγη
/// display (`priceCents − discountCents`, Δ-stat).
typedef PeriodPurchaseRow = ({
  /// AUTOINCREMENT id απόδειξης = αριθμός απόδειξης (§3).
  int receiptId,

  /// Ημερομηνία απόδειξης.
  DateTime date,

  /// Όνομα είδους (JOIN items).
  String itemName,

  /// Όνομα κατηγορίας (JOIN αλυσίδας §3).
  String categoryName,

  /// Όνομα προμηθευτή (JOIN suppliers).
  String supplierName,

  /// Ποσότητα γραμμής (REAL §3).
  double quantity,

  /// FK μονάδας (στήλη προβολής — δυναμικές στήλες ΒΔ, Q3).
  int unitId,

  /// Συντομογραφία μονάδας (JOIN units).
  String unitAbbreviation,

  /// Τιμή μονάδας σε λεπτά (μικτή, §3).
  int priceCents,

  /// Έκπτωση μονάδας σε λεπτά (0 = καμία, §2.2).
  int discountCents,
});

/// Παράμετρος-κλειδί του purchases stream family (§2.3 · 29-09-2026).
///
/// Plain record — value equality για το family cache (pattern
/// `ItemLedgerQuery`, με επιπλέον `sort`).
typedef PeriodPurchasesQuery = ({
  DateTime from,
  DateTime to,
  PurchasesSort sort,
});

/// Δεδομένα αγορών: γραμμές + ένδειξη cap (pattern `ItemTrendData`).
typedef PeriodPurchasesData = ({List<PeriodPurchaseRow> rows, bool truncated});

/// Ομαδοποίηση αναφοράς (§2.3 · 3η ανάλυση «Ομαδοποιημένη αναφορά»).
///
/// Εφαρμόζεται client-side πάνω στις φορτωμένες γραμμές (όχι queries —
/// οι γραμμές είναι ήδη φορτωμένες)· διατηρεί τη σειρά τους (το sort
/// προηγήθηκε στη SQL, τεκμηριωμένο).
enum PurchasesGroup { category, supplier, day, month }

/// Ομάδα γραμμών: κλειδί προβολής + γραμμές (σειρά encounter).
typedef PurchaseGroup = ({String key, List<PeriodPurchaseRow> rows});
