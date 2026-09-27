/// DAO για τον πίνακα `sub_categories` — Refactor 4 επιπέδων 27-09-2026.
///
/// Ομαδοποιημένες ανά category + πλήρης λίστα + counts/cascade (§2.3).
/// SPoT `normalizedName` (pattern `ItemDao`): insert-time + re-calc στο
/// updateById — global UNIQUE (§3). Όλα τα σφάλματα: log + raw rethrow.
library;

import 'package:drift/drift.dart';

import '../../../core/utils/greek_text_normalizer.dart';
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

  /// Διαβάζει υποκατηγορία με βάση το κανονικοποιημένο όνομα (exact-match).
  Future<SubCategory?> getByNormalizedName(String normalizedName) => guard(
        'Αναζήτηση υποκατηγορίας κατά normalizedName',
        () => (db.select(db.subCategories)
              ..where((t) => t.normalizedName.equals(normalizedName)))
            .getSingleOrNull(),
      );

  /// Εισάγει υποκατηγορία σε [categoryId]· το `normalizedName` υπολογίζεται
  /// ΕΔΩ (SPoT §3).
  Future<int> insert({required int categoryId, required String name}) => guard(
        'Εισαγωγή υποκατηγορίας',
        () => db.into(db.subCategories).insert(
              SubCategoriesCompanion.insert(
                categoryId: categoryId,
                name: name,
                normalizedName: GreekTextNormalizer.normalize(name),
              ),
            ),
      );

  /// Ενημερώνει category ή/και name (ξανα-υπολογίζει normalizedName).
  Future<bool> updateById(int id, {int? categoryId, String? name}) => guard(
        'Ενημέρωση υποκατηγορίας',
        () async {
          var companion = const SubCategoriesCompanion();
          if (categoryId != null) {
            companion = companion.copyWith(categoryId: Value(categoryId));
          }
          if (name != null) {
            companion = companion.copyWith(
              name: Value(name),
              normalizedName: Value(GreekTextNormalizer.normalize(name)),
            );
          }
          final rows = await (db.update(db.subCategories)
                ..where((t) => t.id.equals(id)))
              .write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν τμήματα.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή υποκατηγορίας',
        () async {
          final rows = await (db.delete(db.subCategories)
                ..where((t) => t.id.equals(id)))
              .go();
          return rows > 0;
        },
      );

  /// Μετράει τα είδη της υποκατηγορίας — §2.3 (sub→group→item).
  Future<int> countItemsBySubCategoryId(int subCategoryId) => guard(
        'Μέτρηση ειδών υποκατηγορίας',
        () async {
          final countExp = db.items.id.count();
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..join([
              innerJoin(
                db.itemGroups,
                db.itemGroups.id.equalsExp(db.items.itemGroupId),
              ),
            ])
            ..where(db.itemGroups.subCategoryId.equals(subCategoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Μετράει τα είδη με ≥1 γραμμή — πύλη διαγραφής (`0` = καθαρή).
  Future<int> countItemsInUseBySubCategoryId(int subCategoryId) => guard(
        'Μέτρηση χρησιμοποιούμενων ειδών υποκατηγορίας',
        () async {
          final countExp = db.items.id.count(distinct: true);
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..join([
              innerJoin(
                db.receiptLines,
                db.receiptLines.itemId.equalsExp(db.items.id),
              ),
              innerJoin(
                db.itemGroups,
                db.itemGroups.id.equalsExp(db.items.itemGroupId),
              ),
            ])
            ..where(db.itemGroups.subCategoryId.equals(subCategoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Διαγράφει την υποκατηγορία με τμήματα + ορφανά είδη — §2.3.
  /// ΜΟΝΟ όταν καθαρή · σειρά: είδη → τμήματα → υποκατηγορία, 1 transaction.
  Future<bool> deleteWithContents(int subCategoryId) => guard(
        'Διαγραφή υποκατηγορίας με περιεχόμενα',
        () => db.transaction(() async {
          final groupIdsQuery = db.selectOnly(db.itemGroups)
            ..addColumns([db.itemGroups.id])
            ..where(db.itemGroups.subCategoryId.equals(subCategoryId));
          await (db.delete(db.items)
                ..where((t) => t.itemGroupId.isInQuery(groupIdsQuery)))
              .go();
          await (db.delete(db.itemGroups)
                ..where((t) => t.subCategoryId.equals(subCategoryId)))
              .go();
          final rows = await (db.delete(db.subCategories)
                ..where((t) => t.id.equals(subCategoryId)))
              .go();
          return rows > 0;
        }),
      );
}
