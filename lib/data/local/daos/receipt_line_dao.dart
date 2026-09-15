/// DAO για τον πίνακα `receipt_lines` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// SPoT υπολογισμού του `lineTotalCents` (§3): ο υπολογισμός
/// `(priceCents * quantity).round()` γίνεται ΑΠΟΚΛΕΙΣΤΙΚΑ εδώ — ο caller δεν
/// μπορεί ποτέ να δώσει `lineTotalCents` (αποτρέπονται ασυνέπειες). Στο
/// updateById ξανα-υπολογίζεται αυτόματα όταν αλλάζει quantity/priceCents.
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τις γραμμές αποδείξεων.
class ReceiptLineDao extends BaseDao {
  ReceiptLineDao(super.db);

  /// Παρακολουθεί τις γραμμές μιας απόδειξης, με σειρά εισαγωγής (id).
  Stream<List<ReceiptLine>> watchByReceiptId(int receiptId) => guardStream(
        'Ανάγνωση γραμμών απόδειξης',
        () => (db.select(db.receiptLines)
              ..where((t) => t.receiptId.equals(receiptId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .watch(),
      );

  /// Διαβάζει μία γραμμή ή null αν δεν υπάρχει.
  Future<ReceiptLine?> getById(int id) => guard(
        'Ανάγνωση γραμμής απόδειξης',
        () => (db.select(db.receiptLines)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Εισάγει γραμμή. Το `lineTotalCents` υπολογίζεται ΕΔΩ (SPoT §3):
  /// `(priceCents * quantity).round()` — στρογγυλοποίηση στο πλησιέστερο cent.
  Future<int> insert({
    required int receiptId,
    required int itemId,
    required int unitId,
    required double quantity,
    required int priceCents,
  }) =>
      guard(
        'Εισαγωγή γραμμής απόδειξης',
        () => db.into(db.receiptLines).insert(
              ReceiptLinesCompanion.insert(
                receiptId: receiptId,
                itemId: itemId,
                unitId: unitId,
                quantity: quantity,
                priceCents: priceCents,
                lineTotalCents: (priceCents * quantity).round(),
              ),
            ),
      );

  /// Ενημερώνει γραμμή (όσα πεδία δεν είναι null). Αν αλλάζει quantity ΚΑΙ
  /// priceCents, το lineTotalCents ξανα-υπολογίζεται με τα ΝΕΑ value (SPoT §3).
  Future<bool> updateById(
    int id, {
    int? receiptId,
    int? itemId,
    int? unitId,
    double? quantity,
    int? priceCents,
  }) =>
      guard(
        'Ενημέρωση γραμμής απόδειξης',
        () async {
          if (receiptId == null &&
              itemId == null &&
              unitId == null &&
              quantity == null &&
              priceCents == null) {
            return false;
          }
          var companion = const ReceiptLinesCompanion();
          if (receiptId != null) {
            companion = companion.copyWith(receiptId: Value(receiptId));
          }
          if (itemId != null) {
            companion = companion.copyWith(itemId: Value(itemId));
          }
          if (unitId != null) {
            companion = companion.copyWith(unitId: Value(unitId));
          }
          if (quantity != null) {
            companion = companion.copyWith(quantity: Value(quantity));
          }
          if (priceCents != null) {
            companion = companion.copyWith(priceCents: Value(priceCents));
          }
          if (quantity != null || priceCents != null) {
            // Recalculate: χρειαζόμαστε και τα δύο· ό,τι δεν δόθηκε το
            // διαβάζουμε από την υπάρχουσα γραμμή (SPoT §3).
            final current = await (db.select(db.receiptLines)
                  ..where((t) => t.id.equals(id)))
                .getSingleOrNull();
            if (current == null) return false;
            companion = companion.copyWith(
              lineTotalCents: Value(
                ((priceCents ?? current.priceCents) * (quantity ?? current.quantity))
                    .round(),
              ),
            );
          }
          final rows =
              await (db.update(db.receiptLines)..where((t) => t.id.equals(id))).write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή γραμμής — πάντα επιτρεπτή (χωρίς dependents).
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή γραμμής απόδειξης',
        () async {
          final rows =
              await (db.delete(db.receiptLines)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );
}