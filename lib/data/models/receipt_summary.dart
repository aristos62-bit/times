/// SPoT: Σύνοψη απόδειξης για τη λίστα πρόσφατων αποδείξεων — Φάση 3,
/// Βήμα 7 (§2.2 DESIGN).
///
/// Το `ReceiptSummary` είναι **projection**, όχι οντότητα πίνακα: παράγεται
/// αποκλειστικά από το SQL aggregation του `ReceiptDao.watchRecentSummaries`
/// (DESIGN §2.1 «η άθροιση γίνεται στο SQL, όχι φορτώνοντας τις γραμμές στη
/// μνήμη»). Ζει στον ανοιχτό φάκελο `data/models` (§1.2 DESIGN) ως plain
/// record typedef — χωρίς Freezed (τα repos επιστρέφουν Drift data classes /
/// records απευθείας, ίδιο pattern με το `ReceiptLineInput`).
///
/// Πεδία: κεφαλίδα (id = αριθμός απόδειξης, §3), ημερομηνία, προμηθευτής,
/// πλήθος γραμμών και συνολικό ποσό σε λεπτά (SUM του αποθηκευμένου
/// `lineTotalCents` — SPoT υπολογισμού: ReceiptLineDao, §3).
library;

/// Σύνοψη μιας απόδειξης για τη read-only λίστα (§2.2 Βήμα 7).
typedef ReceiptSummary = ({
  /// AUTOINCREMENT id της απόδειξης = αριθμός απόδειξης (§3).
  int id,
  /// Ημερομηνία της απόδειξης.
  DateTime date,
  /// FK → Suppliers.id.
  int supplierId,
  /// Όνομα προμηθευτή (LEFT JOIN, §2.2 Βήμα 7).
  String supplierName,
  /// Πλήθος γραμμών (COUNT) — 0 για απόδειξη χωρίς γραμμές.
  int lineCount,
  /// Συνολικό ποσό σε λεπτά (SUM lineTotalCents) — 0 όταν δεν υπάρχουν γραμμές.
  int totalCents,
});