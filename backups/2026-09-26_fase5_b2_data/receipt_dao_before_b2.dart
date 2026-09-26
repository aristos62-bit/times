/// DAO για τον πίνακα `receipts` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// Η απόδειξη = κεφαλίδα («καλάθι» §2.2): date + supplierId. Ο αριθμός της
/// απόδειξης είναι το AUTOINCREMENT `id` (απόφαση §3 — όχι sequence counter).
/// Οι γραμμές διαχειρίζονται από το ReceiptLineDao (watchByReceiptId).
library;

import 'package:drift/drift.dart';

import '../../models/receipt_summary.dart';
import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τις κεφαλίδες αποδείξεων.
class ReceiptDao extends BaseDao {
  ReceiptDao(super.db);

  /// Παρακολουθεί όλες τις αποδείξεις, νεότερες πρώτα (date desc, id desc).
  Stream<List<Receipt>> watchAll() => guardStream(
        'Ανάγνωση αποδείξεων',
        () => (db.select(db.receipts)
              ..orderBy([
                (t) => OrderingTerm.desc(t.date),
                (t) => OrderingTerm.desc(t.id),
              ]))
            .watch(),
      );

  /// Παρακολουθεί τις τελευταίες [limit] αποδείξεις με σύνοψη για τη
  /// read-only λίστα (§2.2 Βήμα 7).
  ///
  /// SQL aggregation (DESIGN §2.1 «η άθροιση γίνεται στο SQL, όχι στη
  /// μνήμη»): COUNT γραμμών + SUM του αποθηκευμένου `lineTotalCents`
  /// (SPoT υπολογισμού: ReceiptLineDao, §3) πάνω σε LEFT JOIN, ώστε
  /// απόδειξη χωρίς γραμμές να εμφανίζεται με 0/0 (ποτέ δεν «χάνεται» από
  /// τη λίστα). Σειρά: date desc, id desc — ίδια με [watchAll].
  ///
  /// Custom SQL → drift δεν μπορεί να συμπεράνει τους πίνακες: δηλώνουμε
  /// [readsFrom] ώστε το stream να ξανα-εκπέμπει όταν αλλάξει ο,τιδήποτε
  /// στους 3 πίνακες (receipts/suppliers/receipt_lines). Το `read<DateTime>`
  /// για το `r.date` χρησιμοποιεί το default drift mapping
  /// (unix seconds → DateTime) — καμία χειροκίνητη μετατροπή.
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit}) =>
      guardStream(
        'Ανάγνωση πρόσφατων αποδείξεων',
        () => db
            .customSelect(
              '''
        SELECT r.id AS id,
               r.date AS date,
               r.supplier_id AS supplierId,
               s.name AS supplierName,
               COUNT(rl.id) AS lineCount,
               COALESCE(SUM(rl.line_total_cents), 0) AS totalCents
        FROM receipts r
        LEFT JOIN suppliers s      ON s.id = r.supplier_id
        LEFT JOIN receipt_lines rl ON rl.receipt_id = r.id
        GROUP BY r.id, r.date, r.supplier_id, s.name
        ORDER BY r.date DESC, r.id DESC
        LIMIT ?
      ''',
              variables: [Variable.withInt(limit)],
              readsFrom: {db.receipts, db.suppliers, db.receiptLines},
            )
            .watch()
            .map(
              (rows) => rows
                  .map(
                    (row) => (
                      id: row.read<int>('id'),
                      date: row.read<DateTime>('date'),
                      supplierId: row.read<int>('supplierId'),
                      supplierName: row.read<String>('supplierName'),
                      lineCount: row.read<int>('lineCount'),
                      totalCents: row.read<int>('totalCents'),
                    ),
                  )
                  .toList(),
            ),
      );

  /// Παρακολουθεί τις αποδείξεις μίας ημέρας με σύνοψη (§2.3 · Φάση Β).
  ///
  /// Ίδιο SQL aggregation με [watchRecentSummaries] + `WHERE` ημέρας:
  /// `dayStart <= date < dayStart + 1 ημέρα` — τα όρια υπολογίζονται εδώ με
  /// καθαρό `DateTime` (όχι flutter `DateUtils`: το data layer δεν εξαρτάται
  /// από το UI) και καλύπτουν τυχόν time-parts αμυντικά. Σειρά: date desc,
  /// id desc — ίδια με [watchAll].
  Stream<List<ReceiptSummary>> watchSummariesByDay({
    required DateTime day,
    required int limit,
  }) =>
      guardStream(
        'Ανάγνωση αποδείξεων ημέρας',
        () {
          final start = DateTime(day.year, day.month, day.day);
          final end = start.add(const Duration(days: 1));
          return db
              .customSelect(
                '''
        SELECT r.id AS id,
                r.date AS date,
                r.supplier_id AS supplierId,
                s.name AS supplierName,
                COUNT(rl.id) AS lineCount,
                COALESCE(SUM(rl.line_total_cents), 0) AS totalCents
        FROM receipts r
        LEFT JOIN suppliers s      ON s.id = r.supplier_id
        LEFT JOIN receipt_lines rl ON rl.receipt_id = r.id
        WHERE r.date >= ? AND r.date < ?
        GROUP BY r.id, r.date, r.supplier_id, s.name
        ORDER BY r.date DESC, r.id DESC
        LIMIT ?
      ''',
                variables: [
                  Variable.withDateTime(start),
                  Variable.withDateTime(end),
                  Variable.withInt(limit),
                ],
                readsFrom: {db.receipts, db.suppliers, db.receiptLines},
              )
              .watch()
              .map(
                (rows) => rows
                    .map(
                      (row) => (
                        id: row.read<int>('id'),
                        date: row.read<DateTime>('date'),
                        supplierId: row.read<int>('supplierId'),
                        supplierName: row.read<String>('supplierName'),
                        lineCount: row.read<int>('lineCount'),
                        totalCents: row.read<int>('totalCents'),
                      ),
                    )
                    .toList(),
              );
        },
      );

  /// Μετράει τις αποδείξεις ενός προμηθευτή — Ρυθμίσεις, CRUD προμηθευτών
  /// (24-09-2026, §2.3).
  ///
  /// Χρήση: πύλη διαγραφής — `0` = καθαρός (επιτρέπεται delete), `>0` =
  /// μπλοκαρισμένος (greyed-out + tooltip «Ν αποδείξεις», πατρόν Βήματος 4).
  /// Typed drift API (selectOnly + count, compile-time ονόματα — Α2).
  Future<int> countBySupplierId(int supplierId) => guard(
        'Μέτρηση αποδείξεων προμηθευτή',
        () async {
          final countExp = db.receipts.id.count();
          final query = db.selectOnly(db.receipts)
            ..addColumns([countExp])
            ..where(db.receipts.supplierId.equals(supplierId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Διαβάζει μία απόδειξη ή null αν δεν υπάρχει.
  Future<Receipt?> getById(int id) => guard(
        'Ανάγνωση απόδειξης',
        () => (db.select(db.receipts)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Εισάγει απόδειξη· επιστρέφει τον (αυτόματο) αριθμό απόδειξης = id.
  Future<int> insert({required DateTime date, required int supplierId}) => guard(
        'Εισαγωγή απόδειξης',
        () => db.into(db.receipts)
            .insert(ReceiptsCompanion.insert(date: date, supplierId: supplierId)),
      );

  /// Ενημερώνει date/supplierId (όσα δεν είναι null). True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {DateTime? date, int? supplierId}) => guard(
        'Ενημέρωση απόδειξης',
        () async {
          var companion = const ReceiptsCompanion();
          if (date != null) {
            companion = companion.copyWith(date: Value(date));
          }
          if (supplierId != null) {
            companion = companion.copyWith(supplierId: Value(supplierId));
          }
          final rows =
              await (db.update(db.receipts)..where((t) => t.id.equals(id))).write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή. CASCADE (FK §3): σβήνει και τις γραμμές της απόδειξης.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή απόδειξης',
        () async {
          final rows =
              await (db.delete(db.receipts)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );
}