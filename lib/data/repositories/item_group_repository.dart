/// Abstract repository για τα τμήματα (ItemGroups) — 27-09-2026.
///
/// SPoT: Μοναδικό σημείο πρόσβασης στα δεδομένα τμημάτων (DESIGN §1.2).
/// Mirror του `SubCategoryRepository`. Error mapping: reads/writes →
/// `DataLoadException` (προσωρινά, βλ. NOTE στο app_errors.dart).
library;

import '../local/app_database.dart';

/// Abstract interface — υλοποιείται πάνω στον ItemGroupDao.
abstract interface class ItemGroupRepository {
  /// Παρακολουθεί όλα τα τμήματα, αλφαβητικά.
  Stream<List<ItemGroup>> watchAll();

  /// Παρακολουθεί τα τμήματα μιας υποκατηγορίας, αλφαβητικά.
  Stream<List<ItemGroup>> watchBySubCategoryId(int subCategoryId);

  /// Διαβάζει ένα τμήμα ή null αν δεν υπάρχει.
  Future<ItemGroup?> getById(int id);

  /// Διαβάζει τμήμα με βάση το κανονικοποιημένο όνομα (exact-match,
  /// soft dup-check §2.2 — UNIQUE `normalizedName`, §3).
  Future<ItemGroup?> getByNormalizedName(String normalizedName);

  /// Εισάγει τμήμα σε [subCategoryId]· επιστρέφει το νέο id.
  Future<int> insert({required int subCategoryId, required String name});

  /// Ενημερώνει subCategory ή/και name. True αν υπήρξε αλλαγή.
  Future<bool> updateById(int id, {int? subCategoryId, String? name});

  /// Διαγραφή. RESTRICT (FK): αποτυγχάνει αν υπάρχουν items.
  Future<bool> deleteById(int id);

  /// Μετράει τα είδη του τμήματος με ≥1 γραμμή απόδειξης: πύλη διαγραφής
  /// (`0` = καθαρή). Passthrough του DAO με mapping σε `DataLoadException`.
  Future<int> countItemsInUse(int itemGroupId);

  /// Μετράει ΟΛΑ τα είδη του τμήματος: αριθμός στο cascade confirm.
  /// Passthrough του DAO με mapping σε `DataLoadException`.
  Future<int> countItems(int itemGroupId);

  /// Διαγράφει το τμήμα με τα ορφανά είδη του σε ένα transaction.
  /// ΜΟΝΟ όταν `countItemsInUse == 0`. Passthrough του DAO.
  Future<bool> deleteWithContents(int itemGroupId);
}
