/// Abstract repository για τις αποδείξεις — Φάση 2, Βήμα 1 (DESIGN §4).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στα δεδομένα αποδείξεων. Περιλαμβάνει
/// και τις λειτουργίες γραμμών (watchLines, insertReceiptWithLines) —
/// χωρίς ξεχωριστό ReceiptLineRepository (DESIGN §4).
///
/// Error mapping: reads → DataLoadException, insertReceiptWithLines →
/// SaveReceiptException, άλλες writes → DataLoadException
/// (προσωρινά, βλ. NOTE στο app_errors.dart).
library;

import '../local/app_database.dart';
import '../models/chart_totals.dart';
import '../models/receipt_summary.dart';

/// Record για την εισαγωγή γραμμής απόδειξης στη transaction.
/// Το `lineTotalCents` υπολογίζεται στο DAO (SPoT §3) — εδώ μόνο τα βασικά
/// πεδία (`discountCents` = έκπτωση μονάδας, 0 = καμία, §2.2).
typedef ReceiptLineInput = ({
  int itemId,
  int unitId,
  double quantity,
  int priceCents,
  int discountCents,
});

/// Abstract interface — υλοποιείται πάνω στους ReceiptDao + ReceiptLineDao.
abstract interface class ReceiptRepository {
  /// Παρακολουθεί όλες τις αποδείξεις, νεότερες πρώτα.
  Stream<List<Receipt>> watchAll();

  /// Παρακολουθεί τις τελευταίες [limit] αποδείξεις με σύνοψη
  /// (ReceiptSummary) για τη read-only λίστα (Φάση 3, Βήμα 7 §2.2).
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit});

  /// Παρακολουθεί τις αποδείξεις μίας ημέρας με σύνοψη (§2.3 · Φάση Β).
  /// Passthrough στο DAO (Βήμα 2).
  Stream<List<ReceiptSummary>> watchSummariesByDay({
    required DateTime day,
    required int limit,
  });

  /// Παρακολουθεί τα σύνολα ανά προμηθευτή σε περίοδο (§2.1 · Φάση 5).
  /// Passthrough στο DAO (Βήμα 2).
  Stream<List<SupplierTotal>> watchTotalsBySupplier({
    required DateTime from,
    required DateTime to,
  });

  /// Παρακολουθεί τα σύνολα ανά κατηγορία σε περίοδο (§2.1 · Φάση 5).
  /// Passthrough στο DAO (Βήμα 2).
  Stream<List<CategoryTotal>> watchTotalsByCategory({
    required DateTime from,
    required DateTime to,
  });

  /// Παρακολουθεί τα σύνολα ανά υποκατηγορία σε περίοδο (§2.1 · Φάση 5).
  /// Passthrough στο DAO (Βήμα 2).
  Stream<List<SubCategoryTotal>> watchTotalsBySubCategory({
    required DateTime from,
    required DateTime to,
  });

  /// Παρακολουθεί τα σύνολα ανά είδος σε περίοδο (§2.1 · Φάση 5 — Top-10).
  /// Passthrough στο DAO (Βήμα 2).
  Stream<List<ItemTotal>> watchTopItems({
    required DateTime from,
    required DateTime to,
  });

  /// Διαβάζει μία απόδειξη ή null αν δεν υπάρχει.
  Future<Receipt?> getById(int id);

  /// Μετράει τις αποδείξεις ενός προμηθευτή — πύλη διαγραφής προμηθευτή
  /// (§2.3 · 24-09-2026): `0` = καθαρός. Passthrough στο DAO (Βήμα 2).
  Future<int> countBySupplierId(int supplierId);

  /// Εισάγει απόδειξη· επιστρέφει τον (αυτόματο) αριθμό = id.
  Future<int> insert({required DateTime date, required int supplierId});

  /// Ενημερώνει date/supplierId. True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {DateTime? date, int? supplierId});

  /// Διαγραφή. CASCADE (FK §3): σβήνει και τις γραμμές.
  Future<bool> deleteById(int id);

  // ─── Receipt Lines (γραμμές απόδειξης) ──────────────────────────────────

  /// Παρακολουθεί τις γραμμές μιας απόδειξης, με σειρά εισαγωγής.
  Stream<List<ReceiptLine>> watchLines(int receiptId);

  /// Διαβάζει ΟΛΕΣ τις γραμμές μιας απόδειξης (one-shot, σειρά εισαγωγής) —
  /// για φόρτωση edit (Φάση Α). Passthrough στο DAO (Βήμα 2).
  Future<List<ReceiptLine>> getLines(int receiptId);

  /// Τελευταία γραμμή είδους (τιμή+έκπτωση prefill §2.2) — null αν το είδος
  /// δεν έχει κινηθεί ποτέ. Passthrough στο DAO.
  Future<ReceiptLine?> getLatestByItemId(int itemId);

  /// Εισάγει απόδειξη με όλες τις γραμμές σε μία transaction (atomicity).
  /// Επιστρέφει το id της απόδειξης. Αποτυχία → SaveReceiptException.
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  });

  /// Ενημερώνει απόδειξη με αντικατάσταση γραμμών σε μία transaction
  /// (Φάση Α · 24-09-2026): update κεφαλίδας + διαγραφή ΟΛΩΝ των παλιών
  /// γραμμών + insert νέων. Αποτυχία → SaveReceiptException· ανύπαρκτο
  /// id → DataLoadException (pattern rename-ανύπαρκτο §2.3).
  /// Τα line-ids αλλάζουν — αποδεκτό (καμία εξωτερική αναφορά, SUM §3).
  Future<void> updateReceiptWithLines({
    required int id,
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  });
}
