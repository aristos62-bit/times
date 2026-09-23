/// Abstract repository για τις υποκατηγορίες — Φάση 2, Βήμα 1 (DESIGN §4).
///
/// SPoT: Μοναδικό σημείο πρόσβασης στα δεδομένα υποκατηγοριών.
///
/// Error mapping: reads → DataLoadException, writes → DataLoadException
/// (προσωρινά, βλ. NOTE στο app_errors.dart).
library;

import '../local/app_database.dart';

/// Abstract interface — υλοποιείται πάνω στον SubCategoryDao.
abstract interface class SubCategoryRepository {
  /// Παρακολουθεί όλες τις υποκατηγορίες, αλφαβητικά.
  Stream<List<SubCategory>> watchAll();

  /// Παρακολουθεί τις υποκατηγορίες μιας κατηγορίας, αλφαβητικά.
  Stream<List<SubCategory>> watchByCategoryId(int categoryId);

  /// Διαβάζει μία υποκατηγορία ή null αν δεν υπάρχει.
  Future<SubCategory?> getById(int id);

  /// Εισάγει υποκατηγορία σε [categoryId]· επιστρέφει το νέο id.
  Future<int> insert({required int categoryId, required String name});

  /// Ενημερώνει category ή/και name. True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {int? categoryId, String? name});

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν items.
  Future<bool> deleteById(int id);

  /// Μετράει τα είδη της υποκατηγορίας με ≥1 γραμμή απόδειξης — Φάση 4,
  /// Βήμα 3 (§2.3:275): πύλη διαγραφής (`0` = καθαρή). Passthrough του
  /// `SubCategoryDao.countItemsInUseBySubCategoryId` με mapping σε
  /// `DataLoadException` (καταναλωτής: `canDeleteSubCategoryProvider`).
  Future<int> countItemsInUse(int subCategoryId);
}
