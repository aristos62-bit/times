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
typedef ChartSlice = ({String label, int totalCents});
