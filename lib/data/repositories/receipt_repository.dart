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

/// Record για την εισαγωγή γραμμής απόδειξης στη transaction.
/// Το `lineTotalCents` υπολογίζεται στο DAO (SPoT §3) — εδώ μόνο τα βασικά πεδία.
typedef ReceiptLineInput = ({
  int itemId,
  int unitId,
  double quantity,
  int priceCents,
});

/// Abstract interface — υλοποιείται πάνω στους ReceiptDao + ReceiptLineDao.
abstract interface class ReceiptRepository {
  /// Παρακολουθεί όλες τις αποδείξεις, νεότερες πρώτα.
  Stream<List<Receipt>> watchAll();

  /// Διαβάζει μία απόδειξη ή null αν δεν υπάρχει.
  Future<Receipt?> getById(int id);

  /// Εισάγει απόδειξη· επιστρέφει τον (αυτόματο) αριθμό = id.
  Future<int> insert({required DateTime date, required int supplierId});

  /// Ενημερώνει date/supplierId. True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {DateTime? date, int? supplierId});

  /// Διαγραφή. CASCADE (FK §3): σβήνει και τις γραμμές.
  Future<bool> deleteById(int id);

  // ─── Receipt Lines (γραμμές απόδειξης) ──────────────────────────────────

  /// Παρακολουθεί τις γραμμές μιας απόδειξης, με σειρά εισαγωγής.
  Stream<List<ReceiptLine>> watchLines(int receiptId);

  /// Εισάγει απόδειξη με όλες τις γραμμές σε μία transaction (atomicity).
  /// Επιστρέφει το id της απόδειξης. Αποτυχία → SaveReceiptException.
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  });
}
