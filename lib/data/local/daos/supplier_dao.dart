/// DAO για τον πίνακα `suppliers` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// SPoT υπολογισμού του `normalizedName` (όπως ItemDao): υπολογίζεται μόνο
/// εδώ κατά insert/updateById(name) με GreekTextNormalizer.normalize (§3).
/// Το `getByNormalizedName` υποστηρίζει τον duplicate-check (§2.2, exact).
/// Δεν γίνεται seed για suppliers (§4.1.3) — δημιουργούνται χειροκίνητα.
library;

import 'package:drift/drift.dart';

import '../../../core/utils/greek_text_normalizer.dart';
import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τους προμηθευτές.
class SupplierDao extends BaseDao {
  SupplierDao(super.db);

  /// Παρακολουθεί όλους τους προμηθευτές, με σειρά normalizedName.
  Stream<List<Supplier>> watchAll() => guardStream(
        'Ανάγνωση προμηθευτών',
        () => (db.select(db.suppliers)
              ..orderBy([(t) => OrderingTerm.asc(t.normalizedName)]))
            .watch(),
      );

  /// Διαβάζει έναν προμηθευτή ή null αν δεν υπάρχει.
  Future<Supplier?> getById(int id) => guard(
        'Ανάγνωση προμηθευτή',
        () => (db.select(db.suppliers)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Διαβάζει προμηθευτή με βάση το κανονικοποιημένο όνομα (§2.2 exact-match).
  Future<Supplier?> getByNormalizedName(String normalizedName) => guard(
        'Αναζήτηση προμηθευτή κατά normalizedName',
        () => (db.select(db.suppliers)
              ..where((t) => t.normalizedName.equals(normalizedName)))
            .getSingleOrNull(),
      );

  /// Εισάγει προμηθευτή. Το `normalizedName` υπολογίζεται ΕΔΩ (SPoT §3).
  Future<int> insert({required String name}) => guard(
        'Εισαγωγή προμηθευτή',
        () => db.into(db.suppliers).insert(
              SuppliersCompanion.insert(
                name: name,
                normalizedName: GreekTextNormalizer.normalize(name),
              ),
            ),
      );

  /// Ενημερώνει το [name]· ξανα-υπολογίζεται και το normalizedName (SPoT §3).
  Future<bool> updateById(int id, {required String name}) => guard(
        'Ενημέρωση προμηθευτή',
        () async {
          final rows = await (db.update(db.suppliers)..where((t) => t.id.equals(id)))
              .write(SuppliersCompanion(
                name: Value(name),
                normalizedName: Value(GreekTextNormalizer.normalize(name)),
              ));
          return rows > 0;
        },
      );

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν αποδείξεις του.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή προμηθευτή',
        () async {
          final rows =
              await (db.delete(db.suppliers)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );
}