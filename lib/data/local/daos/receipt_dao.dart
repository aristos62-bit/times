/// DAO για τον πίνακα `receipts` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// Η απόδειξη = κεφαλίδα («καλάθι» §2.2): date + supplierId. Ο αριθμός της
/// απόδειξης είναι το AUTOINCREMENT `id` (απόφαση §3 — όχι sequence counter).
/// Οι γραμμές διαχειρίζονται από το ReceiptLineDao (watchByReceiptId).
library;

import 'package:drift/drift.dart';

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

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν γραμμές απόδειξης.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή απόδειξης',
        () async {
          final rows =
              await (db.delete(db.receipts)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );
}