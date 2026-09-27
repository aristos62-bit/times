/// DAO για τον πίνακα `item_groups` (Τμήματα) — Refactor 4 επιπέδων 27-09-2026.
///
/// Τμήματα κάτω από μία υποκατηγορία (π.χ. Φέτα κάτω από Γαλακτοκομικά).
/// Mirror του `SubCategoryDao`: ομαδοποιημένα ανά subCategory + πλήρης
/// λίστα + counts/cascade (§2.3). SPoT `normalizedName` (pattern `ItemDao`)
/// — global UNIQUE (§3). Όλα τα σφάλματα: log + raw rethrow.
library;

import 'package:drift/drift.dart';

import '../../../core/utils/greek_text_normalizer.dart';
import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τα τμήματα.
class ItemGroupDao extends BaseDao {
  ItemGroupDao(super.db);

  /// Παρακολουθεί όλα τα τμήματα, αλφαβητικά (name).
  Stream<List<ItemGroup>> watchAll() => guardStream(
        'Ανάγνωση τμημάτων',
        () => (db.select(db.itemGroups)
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Παρακολουθεί τα τμήματα μιας υποκατηγορίας, αλφαβητικά.
  Stream<List<ItemGroup>> watchBySubCategoryId(int subCategoryId) =>
      guardStream(
        'Ανάγνωση τμημάτων υποκατηγορίας',
        () => (db.select(db.itemGroups)
              ..where((t) => t.subCategoryId.equals(subCategoryId))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Διαβάζει ένα τμήμα ή null αν δεν υπάρχει.
  Future<ItemGroup?> getById(int id) => guard(
        'Ανάγνωση τμήματος',
        () => (db.select(db.itemGroups)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Διαβάζει τμήμα με βάση το κανονικοποιημένο όνομα (exact-match).
  Future<ItemGroup?> getByNormalizedName(String normalizedName) => guard(
        'Αναζήτηση τμήματος κατά normalizedName',
        () => (db.select(db.itemGroups)
              ..where((t) => t.normalizedName.equals(normalizedName)))
            .getSingleOrNull(),
      );

  /// Εισάγει τμήμα σε [subCategoryId]· το `normalizedName` υπολογίζεται
  /// ΕΔΩ (SPoT §3).
  Future<int> insert({required int subCategoryId, required String name}) =>
      guard(
        'Εισαγωγή τμήματος',
        () => db.into(db.itemGroups).insert(
              ItemGroupsCompanion.insert(
                subCategoryId: subCategoryId,
                name: name,
                normalizedName: GreekTextNormalizer.normalize(name),
              ),
            ),
      );

  /// Ενημερώνει subCategory ή/και name (ξανα-υπολογίζει normalizedName).
  Future<bool> updateById(int id, {int? subCategoryId, String? name}) => guard(
        'Ενημέρωση τμήματος',
        () async {
          var companion = const ItemGroupsCompanion();
          if (subCategoryId != null) {
            companion = companion.copyWith(subCategoryId: Value(subCategoryId));
          }
          if (name != null) {
            companion = companion.copyWith(
              name: Value(name),
              normalizedName: Value(GreekTextNormalizer.normalize(name)),
            );
          }
          final rows = await (db.update(db.itemGroups)
                ..where((t) => t.id.equals(id)))
              .write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν items.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή τμήματος',
        () async {
          final rows = await (db.delete(db.itemGroups)
                ..where((t) => t.id.equals(id)))
              .go();
          return rows > 0;
        },
      );

  /// Μετράει τα είδη του τμήματος — §2.3 (confirm cascade + tooltip).
  Future<int> countItemsByItemGroupId(int itemGroupId) => guard(
        'Μέτρηση ειδών τμήματος',
        () async {
          final countExp = db.items.id.count();
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..where(db.items.itemGroupId.equals(itemGroupId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Μετράει τα είδη με ≥1 γραμμή — πύλη διαγραφής (`0` = καθαρή).
  Future<int> countItemsInUseByItemGroupId(int itemGroupId) => guard(
        'Μέτρηση χρησιμοποιούμενων ειδών τμήματος',
        () async {
          final countExp = db.items.id.count(distinct: true);
          final query = db.selectOnly(db.items)
            ..addColumns([countExp])
            ..join([
              innerJoin(
                db.receiptLines,
                db.receiptLines.itemId.equalsExp(db.items.id),
              ),
            ])
            ..where(db.items.itemGroupId.equals(itemGroupId));
          final row = await query.getSingle();
          return row.read(countExp) ?? 0;
        },
      );

  /// Διαγράφει το τμήμα με τα ορφανά είδη του — §2.3.
  /// ΜΟΝΟ όταν καθαρό · σειρά: είδη → τμήμα, 1 transaction.
  Future<bool> deleteWithContents(int itemGroupId) => guard(
        'Διαγραφή τμήματος με περιεχόμενα',
        () => db.transaction(() async {
          await (db.delete(db.items)
                ..where((t) => t.itemGroupId.equals(itemGroupId)))
              .go();
          final rows = await (db.delete(db.itemGroups)
                ..where((t) => t.id.equals(itemGroupId)))
              .go();
          return rows > 0;
        }),
      );
}
