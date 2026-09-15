/// DAO για τον πίνακα `items` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// SPoT υπολογισμού του `normalizedName`: Ο υπολογισμός γίνεται ΑΠΟΚΛΕΙΣΤΙΚΑ
/// εδώ (§3: insert-time με GreekTextNormalizer.normalize) και στο updateById
/// ξανα-υπολογίζεται αυτόματα όταν αλλάζει το `name`. Ο caller δεν μπορεί
/// ποτέ να δώσει `normalizedName` — αποτρέπονται silent bugs (σύμβαση §3).
/// Το `getByNormalizedName` υποστηρίζει τον duplicate-check (§2.2, exact).
library;

import 'package:drift/drift.dart';

import '../../../core/utils/greek_text_normalizer.dart';
import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τα είδη.
class ItemDao extends BaseDao {
  ItemDao(super.db);

  /// Παρακολουθεί όλα τα είδη, με σειρά normalizedName (σταθερή case/tone-free).
  Stream<List<Item>> watchAll() => guardStream(
        'Ανάγνωση ειδών',
        () => (db.select(db.items)
              ..orderBy([(t) => OrderingTerm.asc(t.normalizedName)]))
            .watch(),
      );

  /// Παρακολουθεί τα είδη μιας υποκατηγορίας, με σειρά normalizedName.
  Stream<List<Item>> watchBySubCategoryId(int subCategoryId) => guardStream(
        'Ανάγνωση ειδών υποκατηγορίας',
        () => (db.select(db.items)
              ..where((t) => t.subCategoryId.equals(subCategoryId))
              ..orderBy([(t) => OrderingTerm.asc(t.normalizedName)]))
            .watch(),
      );

  /// Διαβάζει ένα είδος ή null αν δεν υπάρχει.
  Future<Item?> getById(int id) => guard(
        'Ανάγνωση είδους',
        () => (db.select(db.items)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Διαβάζει είδος με βάση το κανονικοποιημένο όνομα (§2.2 exact-match).
  /// Καλείται με query ήδη-normalized (GreekTextNormalizer.normalize).
  Future<Item?> getByNormalizedName(String normalizedName) => guard(
        'Αναζήτηση είδους κατά normalizedName',
        () => (db.select(db.items)
              ..where((t) => t.normalizedName.equals(normalizedName)))
            .getSingleOrNull(),
      );

  /// Εισάγει είδος. Το `normalizedName` υπολογίζεται ΕΔΩ (SPoT §3).
  /// [defaultUnitId] προαιρετικό — η βάση επιβάλλει FK (setNull σε διαγραφή).
  Future<int> insert({
    required int subCategoryId,
    required String name,
    int? defaultUnitId,
  }) =>
      guard(
        'Εισαγωγή είδους',
        () => db.into(db.items).insert(
              ItemsCompanion.insert(
                subCategoryId: subCategoryId,
                name: name,
                normalizedName: GreekTextNormalizer.normalize(name),
                defaultUnitId: Value(defaultUnitId),
              ),
            ),
      );

  /// Ενημερώνει subCategoryId/name/defaultUnitId (όσα δεν είναι null).
  /// Αν αλλάζει το [name], ξανα-υπολογίζεται και το normalizedName (SPoT §3).
  Future<bool> updateById(int id, {int? subCategoryId, String? name, int? defaultUnitId}) =>
      guard(
        'Ενημέρωση είδους',
        () async {
          var companion = const ItemsCompanion();
          if (subCategoryId != null) {
            companion = companion.copyWith(subCategoryId: Value(subCategoryId));
          }
          if (name != null) {
            companion = companion.copyWith(
              name: Value(name),
              normalizedName: Value(GreekTextNormalizer.normalize(name)),
            );
          }
          if (defaultUnitId != null) {
            companion = companion.copyWith(defaultUnitId: Value(defaultUnitId));
          }
          final rows =
              await (db.update(db.items)..where((t) => t.id.equals(id))).write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν γραμμές αποδείξεων.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή είδους',
        () async {
          final rows = await (db.delete(db.items)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );
}