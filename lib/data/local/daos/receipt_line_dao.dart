/// DAO για τον πίνακα `receipt_lines` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// SPoT υπολογισμού του `lineTotalCents` (§3): ο υπολογισμός
/// `((priceCents - discountCents) * quantity).round()` γίνεται ΑΠΟΚΛΕΙΣΤΙΚΑ
/// εδώ — ο caller δεν μπορεί ποτέ να δώσει `lineTotalCents` (αποτρέπονται
/// ασυνέπειες). Στο updateById ξανα-υπολογίζεται αυτόματα όταν αλλάζει
/// quantity/priceCents/discountCents.
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

  /// Διαβάζει ΟΛΕΣ τις γραμμές μιας απόδειξης, με σειρά εισαγωγής (id).
  /// One-shot (αντί `watchByReceiptId`) — για φόρτωση edit (Φάση Α), όπου
  /// το widget-test FakeAsync δεν ολοκληρώνει watch-streams (βλ. runAsync
  /// idiom Βήματος 6 — εδώ αποφεύγεται εξ αρχής με one-shot read).
  Future<List<ReceiptLine>> getByReceiptId(int receiptId) => guard(
        'Ανάγνωση γραμμών απόδειξης',
        () => (db.select(db.receiptLines)
              ..where((t) => t.receiptId.equals(receiptId))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get(),
      );

  /// Διαβάζει μία γραμμή ή null αν δεν υπάρχει.
  Future<ReceiptLine?> getById(int id) => guard(
        'Ανάγνωση γραμμής απόδειξης',
        () => (db.select(db.receiptLines)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Τελευταία γραμμή είδους (για prefill τιμής/έκπτωσης §2.2) — μία γραμμή
  /// ή null αν το είδος δεν έχει κινηθεί ποτέ.
  ///
  /// Σειρά: ημερομηνία απόδειξης DESC, id DESC (όχι σκέτο id — backdated
  /// αποδείξεις και edit-reinsert (§2.2 Φάση Α) αλλάζουν τη σειρά των ids).
  /// Typed join (precedent counts/cascade Βήματος 4, §2.3).
  Future<ReceiptLine?> getLatestByItemId(int itemId) => guard(
        'Ανάγνωση τελευταίας γραμμής είδους',
        () async {
          final query = db.select(db.receiptLines).join([
            innerJoin(
              db.receipts,
              db.receipts.id.equalsExp(db.receiptLines.receiptId),
            ),
          ])
            ..where(db.receiptLines.itemId.equals(itemId))
            ..orderBy([
              OrderingTerm.desc(db.receipts.date),
              OrderingTerm.desc(db.receiptLines.id),
            ])
            ..limit(1);
          final row = await query.getSingleOrNull();
          return row?.readTable(db.receiptLines);
        },
      );

  /// Εισάγει γραμμή. Το `lineTotalCents` υπολογίζεται ΕΔΩ (SPoT §3):
  /// `((priceCents - discountCents) * quantity).round()` — στρογγυλοποίηση
  /// στο πλησιέστερο cent. [discountCents] default 0 = καμία έκπτωση
  /// (υπάρχοντες καλούντες άθικτοι).
  Future<int> insert({
    required int receiptId,
    required int itemId,
    required int unitId,
    required double quantity,
    required int priceCents,
    int discountCents = 0,
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
                discountCents: Value(discountCents),
                lineTotalCents:
                    ((priceCents - discountCents) * quantity).round(),
              ),
            ),
      );

  /// Ενημερώνει γραμμή (όσα πεδία δεν είναι null). Αν αλλάζει quantity,
  /// priceCents Ή discountCents, το lineTotalCents ξανα-υπολογίζεται με τα
  /// ΝΕΑ value (SPoT §3).
  Future<bool> updateById(
    int id, {
    int? receiptId,
    int? itemId,
    int? unitId,
    double? quantity,
    int? priceCents,
    int? discountCents,
  }) =>
      guard(
        'Ενημέρωση γραμμής απόδειξης',
        () async {
          if (receiptId == null &&
              itemId == null &&
              unitId == null &&
              quantity == null &&
              priceCents == null &&
              discountCents == null) {
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
          if (discountCents != null) {
            companion =
                companion.copyWith(discountCents: Value(discountCents));
          }
          if (quantity != null || priceCents != null || discountCents != null) {
            // Recalculate: χρειαζόμαστε και τα τρία· ό,τι δεν δόθηκε το
            // διαβάζουμε από την υπάρχουσα γραμμή (SPoT §3).
            final current = await (db.select(db.receiptLines)
                  ..where((t) => t.id.equals(id)))
                .getSingleOrNull();
            if (current == null) return false;
            companion = companion.copyWith(
              lineTotalCents: Value(
                (((priceCents ?? current.priceCents) -
                            (discountCents ?? current.discountCents)) *
                        (quantity ?? current.quantity))
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