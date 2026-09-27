/// DAO για τον πίνακα `items` — Refactor 4 επιπέδων 27-09-2026.
///
/// SPoT υπολογισμού του `normalizedName`: Ο υπολογισμός γίνεται ΑΠΟΚΛΕΙΣΤΙΚΑ
/// εδώ (§3: insert-time με GreekTextNormalizer.normalize) και στο updateById
/// ξανα-υπολογίζεται αυτόματα όταν αλλάζει το `name`. Το είδος ανήκει πάντα
/// σε ένα Τμήμα (`itemGroupId` → ItemGroups). Το `getByNormalizedName`
/// υποστηρίζει τον duplicate-check (§2.2, exact).
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

  /// Παρακολουθεί τα είδη ενός τμήματος, με σειρά normalizedName.
  Stream<List<Item>> watchByItemGroupId(int itemGroupId) => guardStream(
        'Ανάγνωση ειδών τμήματος',
        () => (db.select(db.items)
              ..where((t) => t.itemGroupId.equals(itemGroupId))
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
    required int itemGroupId,
    required String name,
    int? defaultUnitId,
  }) =>
      guard(
        'Εισαγωγή είδους',
        () => db.into(db.items).insert(
              ItemsCompanion.insert(
                itemGroupId: itemGroupId,
                name: name,
                normalizedName: GreekTextNormalizer.normalize(name),
                defaultUnitId: Value(defaultUnitId),
              ),
            ),
      );

  /// Ενημερώνει itemGroupId/name/defaultUnitId (όσα δεν είναι null).
  /// Αν αλλάζει το [name], ξανα-υπολογίζεται και το normalizedName (SPoT §3).
  /// Το [defaultUnitId] δέχεται `Value<int?>` ώστε `Value(null)` = καθάρισμα,
  /// ενώ `const Value.absent()` = μην το πειράξεις (§2.3).
  Future<bool> updateById(
    int id, {
    int? itemGroupId,
    String? name,
    Value<int?>? defaultUnitId,
  }) =>
      guard(
        'Ενημέρωση είδους',
        () async {
          var companion = const ItemsCompanion();
          if (itemGroupId != null) {
            companion = companion.copyWith(itemGroupId: Value(itemGroupId));
          }
          if (name != null) {
            companion = companion.copyWith(
              name: Value(name),
              normalizedName: Value(GreekTextNormalizer.normalize(name)),
            );
          }
          if (defaultUnitId != null) {
            companion = companion.copyWith(defaultUnitId: defaultUnitId);
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
