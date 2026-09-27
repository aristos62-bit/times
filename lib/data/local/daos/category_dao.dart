/// DAO για τον πίνακα `categories` — Refactor 4 επιπέδων 27-09-2026.
///
/// Καθαρό CRUD + streams + counts/cascade (§2.3). SPoT `normalizedName`:
/// υπολογίζεται ΑΠΟΚΛΕΙΣΤΙΚΑ εδώ (insert-time + re-calc στο updateById,
/// pattern `ItemDao`) — global UNIQUE (§3: καμία επανάληψη ονόματος).
/// Όλα τα σφάλματα: log (tag DB) + raw rethrow μέσω BaseDao — το mapping
/// σε AppException γίνεται στο Repository.
library;

import 'package:drift/drift.dart';

import '../../../core/utils/greek_text_normalizer.dart';
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

  /// Διαβάζει κατηγορία με βάση το κανονικοποιημένο όνομα (exact-match,
  /// pattern `ItemDao.getByNormalizedName` — soft dup-check §2.2).
  Future<Category?> getByNormalizedName(String normalizedName) => guard(
        'Αναζήτηση κατηγορίας κατά normalizedName',
        () => (db.select(db.categories)
              ..where((t) => t.normalizedName.equals(normalizedName)))
            .getSingleOrNull(),
      );

  /// Εισάγει κατηγορία· το `normalizedName` υπολογίζεται ΕΔΩ (SPoT §3).
  Future<int> insert({required String name}) => guard(
        'Εισαγωγή κατηγορίας',
        () => db.into(db.categories).insert(
              CategoriesCompanion.insert(
                name: name,
                normalizedName: GreekTextNormalizer.normalize(name),
              ),
            ),
      );

  /// Ενημερώνει το όνομα (ξανα-υπολογίζει normalizedName). True αν άλλαξε.
  Future<bool> updateById(int id, {required String name}) => guard(
        'Ενημέρωση κατηγορίας',
        () async {
          final rows = await (db.update(db.categories)..where((t) => t.id.equals(id)))
              .write(
            CategoriesCompanion(
              name: Value(name),
              normalizedName: Value(GreekTextNormalizer.normalize(name)),
            ),
          );
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

  /// Μετράει τα είδη της κατηγορίας — §2.3 (4 επίπεδα: cat→sub→group→item).
  ///
  /// Χρήση: αριθμός στο cascade confirm + tooltip όταν μπλοκαρισμένη.
  /// Άθροιση στο SQL με typed drift API (compile-time ονόματα).
  Future<int> countItemsByCategoryId(int categoryId) => guard(
        'Μέτρηση ειδών κατηγορίας',
        () async {
          final countExp = db.items.id.count();
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..join([
              innerJoin(
                db.itemGroups,
                db.itemGroups.id.equalsExp(db.items.itemGroupId),
              ),
              innerJoin(
                db.subCategories,
                db.subCategories.id.equalsExp(db.itemGroups.subCategoryId),
              ),
            ])
            ..where(db.subCategories.categoryId.equals(categoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Μετράει τα είδη της κατηγορίας με τουλάχιστον μία γραμμή απόδειξης.
  ///
  /// Πύλη διαγραφής — `0` = καθαρή (cascade), `>0` = μπλοκαρισμένη.
  /// COUNT(DISTINCT items.id) πάνω σε join με τις γραμμές.
  Future<int> countItemsInUseByCategoryId(int categoryId) => guard(
        'Μέτρηση χρησιμοποιούμενων ειδών κατηγορίας',
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
              innerJoin(
                db.subCategories,
                db.subCategories.id.equalsExp(db.itemGroups.subCategoryId),
              ),
            ])
            ..where(db.subCategories.categoryId.equals(categoryId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Διαγράφει την κατηγορία με όλο το περιεχόμενό της (υποκατηγορίες +
  /// τμήματα + ορφανά είδη) — §2.3, αποφάσεις Α/Γ.
  ///
  /// ΜΟΝΟ όταν `countItemsInUseByCategoryId == 0` (έλεγχος στον provider).
  /// Σειρά: είδη → τμήματα → υποκατηγορίες → κατηγορία, ΕΝΑ transaction.
  /// Subqueries (`isInQuery`) — κανένα branch άδειας λίστας, κανένα race.
  Future<bool> deleteWithContents(int categoryId) => guard(
        'Διαγραφή κατηγορίας με περιεχόμενα',
        () => db.transaction(() async {
          final subIdsQuery = db.selectOnly(db.subCategories)
            ..addColumns([db.subCategories.id])
            ..where(db.subCategories.categoryId.equals(categoryId));
          final groupIdsQuery = db.selectOnly(db.itemGroups)
            ..addColumns([db.itemGroups.id])
            ..where(
              (db.itemGroups.subCategoryId.isInQuery(subIdsQuery)),
            );
          await (db.delete(db.items)
                ..where((t) => t.itemGroupId.isInQuery(groupIdsQuery)))
              .go();
          await (db.delete(db.itemGroups)
                ..where((t) => t.subCategoryId.isInQuery(subIdsQuery)))
              .go();
          await (db.delete(db.subCategories)
                ..where((t) => t.categoryId.equals(categoryId)))
              .go();
          final rows = await (db.delete(db.categories)
                ..where((t) => t.id.equals(categoryId)))
              .go();
          return rows > 0;
        }),
      );
}
