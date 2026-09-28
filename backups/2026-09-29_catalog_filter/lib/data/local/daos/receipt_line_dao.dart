/// DAO για τον πίνακα `receipt_lines` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// SPoT υπολογισμού του `lineTotalCents` (§3): ο υπολογισμός
/// `((priceCents - discountCents) * quantity).round()` γίνεται ΑΠΟΚΛΕΙΣΤΙΚΑ
/// εδώ — ο caller δεν μπορεί ποτέ να δώσει `lineTotalCents` (αποτρέπονται
/// ασυνέπειες). Στο updateById ξανα-υπολογίζεται αυτόματα όταν αλλάζει
/// quantity/priceCents/discountCents.
library;

import 'package:drift/drift.dart';

import '../../models/chart_totals.dart';
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

  /// Παρακολουθεί το ιστορικό γραμμών ενός είδους σε περίοδο (§2.1 ·
  /// 28-09-2026 — 6ο γράφημα «Πορεία τιμής»).
  ///
  /// Custom SQL (precedent totals `ReceiptDao`): INNER JOIN αποδείξεων (+
  /// προμηθευτών για το label) με `WHERE item_id = ? AND r.date >= from AND
  /// r.date < to` (όρια resolver Βήματος 3, ως δίνονται). `netPriceCents`
  /// computed `price_cents − discount_cents` (Δ-stat §3 — ποτέ σκέτο price).
  /// Σειρά: ημερομηνία ASC, id ASC (backdated/edit-reinsert, precedent
  /// `getLatestByItemId`). Πλήρης λίστα (χωρίς LIMIT — το cap Q4 γίνεται
  /// στον provider). `readsFrom` → auto-refresh μετά από save/update/delete.
  Stream<List<ItemPricePoint>> watchItemHistory({
    required int itemId,
    required DateTime from,
    required DateTime to,
  }) =>
      guardStream(
        'Ανάγνωση ιστορικού είδους',
        () => db
            .customSelect(
              '''
        SELECT r.date AS date,
               (rl.price_cents - rl.discount_cents) AS netPrice,
               rl.quantity AS quantity,
               rl.unit_id AS unitId,
               s.name AS supplierName
        FROM receipt_lines rl
        INNER JOIN receipts r ON r.id = rl.receipt_id
        INNER JOIN suppliers s ON s.id = r.supplier_id
        WHERE rl.item_id = ? AND r.date >= ? AND r.date < ?
        ORDER BY r.date ASC, rl.id ASC
      ''',
              variables: [
                Variable.withInt(itemId),
                Variable.withDateTime(from),
                Variable.withDateTime(to),
              ],
              readsFrom: {db.receiptLines, db.receipts, db.suppliers},
            )
            .watch()
            .map(
              (rows) => rows
                  .map(
                    (row) => (
                      date: row.read<DateTime>('date'),
                      netPriceCents: row.read<int>('netPrice'),
                      quantity: row.read<double>('quantity'),
                      unitId: row.read<int>('unitId'),
                      supplierName: row.read<String>('supplierName'),
                    ),
                  )
                  .toList(),
            ),
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

  /// Μετράει τις γραμμές ενός είδους — Ρυθμίσεις, πύλη διαγραφής είδους
  /// (§2.3 · CRUD ειδών).
  ///
  /// Χρήση: πύλη διαγραφής — `0` = καθαρό (επιτρέπεται delete), `>0` =
  /// μπλοκαρισμένο (greyed-out + tooltip, πατρόν Βήματος 4). Typed drift API
  /// (selectOnly + count, compile-time ονόματα — Α2).
  Future<int> countByItemId(int itemId) => guard(
        'Μέτρηση γραμμών είδους',
        () async {
          final countExp = db.receiptLines.id.count();
          final query = db.selectOnly(db.receiptLines)
            ..addColumns([countExp])
            ..where(db.receiptLines.itemId.equals(itemId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
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

  /// Παρακολουθεί τις γραμμές ενός είδους με πλήρη στοιχεία καρτέλας
  /// (§2.3 · 28-09-2026 — 1η στατιστική ανάλυση).
  ///
  /// Custom SQL (precedent `watchItemHistory`): joins αποδείξεων +
  /// προμηθευτών + μονάδων (συντομογραφία για «0,456 κιλ») με
  /// `WHERE item_id = ? AND r.date >= from AND r.date < to` (όρια resolver).
  /// Stored τιμές §3 (τιμή/έκπτωση χωριστά — η καθαρή παράγεται στην
  /// προβολή, Δ-stat). ΟΛΕΣ οι μονάδες (η γραμμή φέρει μονάδα, Q3 — αντίθετα
  /// με το φίλτρο πορείας). Σειρά: ημερομηνία ASC, id ASC (backdated,
  /// precedent `getLatestByItemId`). Πλήρης λίστα (cap στον provider).
  /// `readsFrom` → auto-refresh μετά από save/update/delete.
  Stream<List<ItemLedgerRow>> watchItemLedger({
    required int itemId,
    required DateTime from,
    required DateTime to,
  }) =>
      guardStream(
        'Ανάγνωση καρτέλας είδους',
        () => db
            .customSelect(
              '''
        SELECT rl.receipt_id AS receiptId,
               r.date AS date,
               s.name AS supplierName,
               rl.quantity AS quantity,
               u.abbreviation AS unitAbbreviation,
               rl.price_cents AS priceCents,
               rl.discount_cents AS discountCents
        FROM receipt_lines rl
        INNER JOIN receipts r  ON r.id = rl.receipt_id
        INNER JOIN suppliers s ON s.id = r.supplier_id
        INNER JOIN units u     ON u.id = rl.unit_id
        WHERE rl.item_id = ? AND r.date >= ? AND r.date < ?
        ORDER BY r.date ASC, rl.id ASC
      ''',
              variables: [
                Variable.withInt(itemId),
                Variable.withDateTime(from),
                Variable.withDateTime(to),
              ],
              readsFrom: {
                db.receiptLines,
                db.receipts,
                db.suppliers,
                db.units,
              },
            )
            .watch()
            .map(
              (rows) => rows
                  .map(
                    (row) => (
                      receiptId: row.read<int>('receiptId'),
                      date: row.read<DateTime>('date'),
                      supplierName: row.read<String>('supplierName'),
                      quantity: row.read<double>('quantity'),
                      unitAbbreviation:
                          row.read<String>('unitAbbreviation'),
                      priceCents: row.read<int>('priceCents'),
                      discountCents: row.read<int>('discountCents'),
                    ),
                  )
                  .toList(),
            ),
      );

  /// Παρακολουθεί ΟΛΕΣ τις γραμμές-αγορές περιόδου (§2.3 · 29-09-2026 —
  /// 2η ανάλυση «Συνολικές αγορές»).
  ///
  /// Custom SQL: joins αλυσίδας καταλόγου (categories ← sub ← groups ←
  /// items) + receipts + suppliers + units. `ORDER BY` ανά [sort] με
  /// tiebreak ημερομηνία/id (ντετερμινιστική — precedent totals §2.1, που
  /// βάζουν `name ASC` δεύτερο). Stored τιμές §3 · ΟΛΕΣ οι μονάδες (η
  /// στήλη προβολής βγαίνει ανά `unitId`, Q3). Πλήρης λίστα (cap provider).
  /// `readsFrom` → auto-refresh μετά από save/update/delete.
  Stream<List<PeriodPurchaseRow>> watchPeriodPurchases({
    required DateTime from,
    required DateTime to,
    required PurchasesSort sort,
  }) =>
      guardStream(
        'Ανάγνωση συγκεντρωτικών αγορών',
        () {
          final orderBy = switch (sort) {
            PurchasesSort.dateAsc => 'r.date ASC, rl.id ASC',
            PurchasesSort.dateDesc => 'r.date DESC, rl.id DESC',
            PurchasesSort.supplier =>
              's.name ASC, r.date ASC, rl.id ASC',
            PurchasesSort.category =>
              'c.name ASC, r.date ASC, rl.id ASC',
          };
          return db
              .customSelect(
                '''
        SELECT rl.receipt_id AS receiptId,
               r.date AS date,
               i.name AS itemName,
               c.name AS categoryName,
               s.name AS supplierName,
               rl.quantity AS quantity,
               rl.unit_id AS unitId,
               u.abbreviation AS unitAbbreviation,
               rl.price_cents AS priceCents,
               rl.discount_cents AS discountCents
        FROM receipt_lines rl
        INNER JOIN receipts r      ON r.id = rl.receipt_id
        INNER JOIN suppliers s     ON s.id = r.supplier_id
        INNER JOIN items i         ON i.id = rl.item_id
        INNER JOIN units u         ON u.id = rl.unit_id
        INNER JOIN item_groups ig  ON ig.id = i.item_group_id
        INNER JOIN sub_categories sc ON sc.id = ig.sub_category_id
        INNER JOIN categories c    ON c.id = sc.category_id
        WHERE r.date >= ? AND r.date < ?
        ORDER BY $orderBy
      ''',
                variables: [
                  Variable.withDateTime(from),
                  Variable.withDateTime(to),
                ],
                readsFrom: {
                  db.receiptLines,
                  db.receipts,
                  db.suppliers,
                  db.items,
                  db.units,
                  db.itemGroups,
                  db.subCategories,
                  db.categories,
                },
              )
              .watch()
              .map(
                (rows) => rows
                    .map(
                      (row) => (
                        receiptId: row.read<int>('receiptId'),
                        date: row.read<DateTime>('date'),
                        itemName: row.read<String>('itemName'),
                        categoryName: row.read<String>('categoryName'),
                        supplierName: row.read<String>('supplierName'),
                        quantity: row.read<double>('quantity'),
                        unitId: row.read<int>('unitId'),
                        unitAbbreviation:
                            row.read<String>('unitAbbreviation'),
                        priceCents: row.read<int>('priceCents'),
                        discountCents: row.read<int>('discountCents'),
                      ),
                    )
                    .toList(),
              );
        },
      );
}