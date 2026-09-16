/// Abstract repository για τους προμηθευτές — Φάση 2, Βήμα 1 (DESIGN §4).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στα δεδομένα προμηθευτών. Η αναζήτηση
/// `searchByNormalizedName` ορίζεται στα Repositories (όχι στα DAOs —
/// DESIGN §4 Φάση 2).
///
/// Error mapping: reads → DataLoadException, writes → DataLoadException
/// (προσωρινά, βλ. NOTE στο app_errors.dart).
library;

import '../local/app_database.dart';

/// Abstract interface — υλοποιείται πάνω στον SupplierDao.
abstract interface class SupplierRepository {
  /// Παρακολουθεί όλους τους προμηθευτές, με σειρά normalizedName.
  Stream<List<Supplier>> watchAll();

  /// Διαβάζει έναν προμηθευτή ή null αν δεν υπάρχει.
  Future<Supplier?> getById(int id);

  /// Διαβάζει προμηθευτή με βάση το κανονικοποιημένο όνομα (exact-match).
  Future<Supplier?> getByNormalizedName(String normalizedName);

  /// Αναζήτηση προμηθευτών με LIKE στο normalizedName.
  /// [query] πρέπει να είναι ήδη κανονικοποιημένο (GreekTextNormalizer).
  /// Κενό query → κενό stream. Εξάγεται `%`/`_` από το input.
  Stream<List<Supplier>> searchByNormalizedName(String query, {int? limit});

  /// Εισάγει προμηθευτή· επιστρέφει το νέο id.
  Future<int> insert({required String name});

  /// Ενημερώνει το όνομα. True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {required String name});

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν αποδείξεις.
  Future<bool> deleteById(int id);
}
