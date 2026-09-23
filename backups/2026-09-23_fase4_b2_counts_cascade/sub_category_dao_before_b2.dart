/// DAO για τον πίνακα `sub_categories` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// Ομαδοποιημένες ανά category (watchByCategoryId) + πλήρης λίστα
/// αλφαβητικά. Όλα τα σφάλματα: log (tag DB) + raw rethrow (BaseDao);
/// mapping σε AppException στο Repository (Φάση 2).
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τις υποκατηγορίες.
class SubCategoryDao extends BaseDao {
  SubCategoryDao(super.db);

  /// Παρακολουθεί όλες τις υποκατηγορίες, αλφαβητικά (name).
  Stream<List<SubCategory>> watchAll() => guardStream(
        'Ανάγνωση υποκατηγοριών',
        () => (db.select(db.subCategories)
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Παρακολουθεί τις υποκατηγορίες μιας κατηγορίας, αλφαβητικά.
  Stream<List<SubCategory>> watchByCategoryId(int categoryId) => guardStream(
        'Ανάγνωση υποκατηγοριών κατηγορίας',
        () => (db.select(db.subCategories)
              ..where((t) => t.categoryId.equals(categoryId))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Διαβάζει μία υποκατηγορία ή null αν δεν υπάρχει.
  Future<SubCategory?> getById(int id) => guard(
        'Ανάγνωση υποκατηγορίας',
        () => (db.select(db.subCategories)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Εισάγει υποκατηγορία σε [categoryId]· επιστρέφει το νέο id.
  Future<int> insert({required int categoryId, required String name}) => guard(
        'Εισαγωγή υποκατηγορίας',
        () => db.into(db.subCategories).insert(
              SubCategoriesCompanion.insert(categoryId: categoryId, name: name),
            ),
      );

  /// Ενημερώνει category ή/και name (όσα δεν είναι null). True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {int? categoryId, String? name}) => guard(
        'Ενημέρωση υποκατηγορίας',
        () async {
          var companion = const SubCategoriesCompanion();
          if (categoryId != null) {
            companion = companion.copyWith(categoryId: Value(categoryId));
          }
          if (name != null) {
            companion = companion.copyWith(name: Value(name));
          }
          final rows = await (db.update(db.subCategories)
                ..where((t) => t.id.equals(id)))
              .write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν items σε αυτή.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή υποκατηγορίας',
        () async {
          final rows = await (db.delete(db.subCategories)
                ..where((t) => t.id.equals(id)))
              .go();
          return rows > 0;
        },
      );
}