/// DAO για τον πίνακα `units` — Φάση 1, Βήμα 2 (§3, §4.1 DESIGN).
///
/// Καθαρό CRUD + streams. Το `allowsDecimal` είναι πεδίο του πίνακα (seed
/// Βήμα 3 ορίζει τιμές· οι μονάδες δεν δημιουργούνται από το UI, αλλά το
/// DAO παραμένει πλήρες CRUD). Σφάλματα: log (tag DB) + raw rethrow (BaseDao).
library;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../base_dao.dart';

/// CRUD + streams για τις μονάδες μέτρησης.
class UnitDao extends BaseDao {
  UnitDao(super.db);

  /// Παρακολουθεί όλες τις μονάδες, αλφαβητικά (name).
  Stream<List<Unit>> watchAll() => guardStream(
        'Ανάγνωση μονάδων',
        () => (db.select(db.units)..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .watch(),
      );

  /// Διαβάζει μία μονάδα ή null αν δεν υπάρχει.
  Future<Unit?> getById(int id) => guard(
        'Ανάγνωση μονάδας',
        () => (db.select(db.units)..where((t) => t.id.equals(id)))
            .getSingleOrNull(),
      );

  /// Εισάγει μονάδα· επιστρέφει το νέο id.
  Future<int> insert({
    required String name,
    required String abbreviation,
    bool allowsDecimal = false,
  }) =>
      guard(
        'Εισαγωγή μονάδας',
        () => db.into(db.units).insert(
              UnitsCompanion.insert(
                name: name,
                abbreviation: abbreviation,
                allowsDecimal: Value(allowsDecimal),
              ),
            ),
      );

  /// Ενημερώνει name/abbreviation/allowsDecimal (όσα δεν είναι null).
  Future<bool> updateById(int id, {String? name, String? abbreviation, bool? allowsDecimal}) =>
      guard(
        'Ενημέρωση μονάδας',
        () async {
          var companion = const UnitsCompanion();
          if (name != null) {
            companion = companion.copyWith(name: Value(name));
          }
          if (abbreviation != null) {
            companion = companion.copyWith(abbreviation: Value(abbreviation));
          }
          if (allowsDecimal != null) {
            companion = companion.copyWith(allowsDecimal: Value(allowsDecimal));
          }
          final rows =
              await (db.update(db.units)..where((t) => t.id.equals(id))).write(companion);
          return rows > 0;
        },
      );

  /// Διαγραφή. Καμία εξάρτηση (RESTRICT) από backed units δεν προκύπτει
  /// για μονάδες-«ελεύθερες»· αν χρησιμοποιείται από Item/ReceiptLine
  /// η βάση ρίχνει raw constraint error.
  Future<bool> deleteById(int id) => guard(
        'Διαγραφή μονάδας',
        () async {
          final rows =
              await (db.delete(db.units)..where((t) => t.id.equals(id))).go();
          return rows > 0;
        },
      );
}