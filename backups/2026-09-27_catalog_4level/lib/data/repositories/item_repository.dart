/// Abstract repository για τα είδη — Φάση 2, Βήμα 1 (DESIGN §4).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στα δεδομένα ειδών. Η αναζήτηση
/// `searchByNormalizedName` ορίζεται στα Repositories (όχι στα DAOs —
/// DESIGN §4 Φάση 2).
///
/// Error mapping: reads → DataLoadException, writes → DataLoadException
/// (προσωρινά, βλ. NOTE στο app_errors.dart).
library;

import 'package:drift/drift.dart';

import '../local/app_database.dart';

/// Abstract interface — υλοποιείται πάνω στον ItemDao.
abstract interface class ItemRepository {
  /// Παρακολουθεί όλα τα είδη, με σειρά normalizedName.
  Stream<List<Item>> watchAll();

  /// Παρακολουθεί τα είδη μιας υποκατηγορίας, με σειρά normalizedName.
  Stream<List<Item>> watchBySubCategoryId(int subCategoryId);

  /// Διαβάζει ένα είδος ή null αν δεν υπάρχει.
  Future<Item?> getById(int id);

  /// Διαβάζει είδος με βάση το κανονικοποιημένο όνομα (exact-match).
  Future<Item?> getByNormalizedName(String normalizedName);

  /// Αναζήτηση ειδών με LIKE στο normalizedName.
  /// [query] πρέπει να είναι ήδη κανονικοποιημένο (GreekTextNormalizer).
  /// Κενό query → κενό stream. Εξάγεται `%`/`_` από το input.
  Stream<List<Item>> searchByNormalizedName(String query, {int? limit});

  /// Εισάγει είδος· επιστρέφει το νέο id.
  Future<int> insert({
    required int subCategoryId,
    required String name,
    int? defaultUnitId,
  });

  /// Ενημερώνει subCategoryId/name/defaultUnitId (όσα δεν είναι null).
  /// [defaultUnitId] δέχεται `Value<int?>` ώστε:
  /// - `Value(null)` = καθάρισμα (χωρίς προτεινόμενη μονάδα)
  /// - `const Value.absent()` = μην το πειράξεις
  Future<bool> updateById(
    int id, {
    int? subCategoryId,
    String? name,
    Value<int?>? defaultUnitId,
  });

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν receipt lines.
  Future<bool> deleteById(int id);
}
