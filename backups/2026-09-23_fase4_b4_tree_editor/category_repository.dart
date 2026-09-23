/// Abstract repository για τις κατηγορίες — Φάση 2, Βήμα 1 (DESIGN §4).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στα δεδομένα κατηγοριών. Οι
/// controllers/pages δεν καλούν ποτέ τον CategoryDao απευθείας (DESIGN §1.2).
///
/// Error mapping: τα DAOs ρίχνουν raw SqliteException (BaseDao guard).
/// Το implementation mapάρει σε AppException — reads → DataLoadException,
/// writes → DataLoadException (προσωρινά, θα αντικατασταθεί στη Φάση 3/4
/// με validators — βλ. NOTE στο app_errors.dart).
library;

import '../local/app_database.dart';

/// Abstract interface — υλοποιείται πάνω στον CategoryDao.
abstract interface class CategoryRepository {
  /// Παρακολουθεί όλες τις κατηγορίες, αλφαβητικά (DESIGN §3).
  Stream<List<Category>> watchAll();

  /// Διαβάζει μία κατηγορία ή null αν δεν υπάρχει.
  Future<Category?> getById(int id);

  /// Εισάγει κατηγορία· επιστρέφει το νέο id.
  Future<int> insert({required String name});

  /// Ενημερώνει το όνομα. Επιστρέφει true αν άλλαξε 1 γραμμή.
  Future<bool> updateById(int id, {required String name});

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν υποκατηγορίες.
  Future<bool> deleteById(int id);

  /// Μετράει τα είδη της κατηγορίας με ≥1 γραμμή απόδειξης — Φάση 4,
  /// Βήμα 3 (§2.3:275): πύλη διαγραφής (`0` = καθαρή). Passthrough του
  /// `CategoryDao.countItemsInUseByCategoryId` με mapping σε
  /// `DataLoadException` (καταναλωτής: `canDeleteCategoryProvider`).
  Future<int> countItemsInUse(int categoryId);
}
