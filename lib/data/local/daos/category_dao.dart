/// DAO για τον πίνακα `categories` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// Καθαρό CRUD + streams. Δεν υπάρχουν υπολογισμένα πεδία (normalizedName
/// είναι μόνο σε Item/Supplier). Όλα τα σφάλματα: log (tag DB) + raw rethrow
/// μέσω BaseDao — το mapping σε AppException γίνεται στο Repository (Φάση 2).
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τις κατηγορίες ειδών.
class CategoryDao extends BaseDao {
  CategoryDao(super.db);

  /// Παρακολουθεί όλες τις κατηγορίες, αλφαβητικά (name).
  Stream<List<Category>> watchAll() => guardStream(
        'Ανάγνωση κατηγοριών',
        () => (db.select(db.categories)..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Διαβάζει μία κατηγορία ή null αν δεν υπάρχει.
  Future<Category?> getById(int id) => guard(
        'Ανάγνωση κατηγορίας',
        () => (db.select(db.categories)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Εισάγει κατηγορία· επιστρέφει το νέο id.
  Future<int> insert({required String name}) => guard(
        'Εισαγωγή κατηγορίας',
        () => db.into(db.categories).insert(CategoriesCompanion.insert(name: name)),
      );

  /// Ενημερώνει το όνομα. Επιστρέφει true αν άλλαξε 1 γραμμή.
  Future<bool> updateById(int id, {required String name}) => guard(
        'Ενημέρωση κατηγορίας',
        () async {
          final rows = await (db.update(db.categories)..where((t) => t.id.equals(id)))
              .write(CategoriesCompanion(name: Value(name)));
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν υποκατηγορίες.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή κατηγορίας',
        () async {
          final rows = await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );
}