import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/category_dao.dart';

export '../../../../core/database/daos/category_dao.dart'
    show CategoryDuplicateNameException;

/// SPO: Category Repository — abstract contract (Phase 2 Step 4).
///
/// Route A-Συνεπές: καθαρός delegate πάνω στον CategoryDao. Τύποι: τα drift
/// DataClasses (`Category`/`CategoriesCompanion`) ως current SPoT entities.
/// Η δομή δέντρου (parent/child) αντικατοπτρίζεται στα reactive queries.
///
/// Reactive (Stream) για δεδομένα που αλλάζουν συχνά, Future για single-shot.
abstract class CategoryRepository {
  /// Watch όλες τις ενεργές κατηγορίες (reactive, sorted by level/sortOrder)
  Stream<List<Category>> watchAll();

  /// Watch πλήρες δέντρο κατηγοριών — parent/child ομαδοποίηση (reactive)
  Stream<List<Category>> watchTree();

  /// Watch μία κατηγορία μαζί με όλα τα έμμεσα παιδιά της (recursive CTE)
  Stream<List<Category>> watchWithChildrenRecursively(int rootId);

  /// Get category by id
  Future<Category?> getById(int id);

  /// Δημιουργία κατηγορίας — return: νέο id.
  /// Πετάει [CategoryDuplicateNameException] αν υπάρχει ήδη ίδιο name στο
  /// ίδιο επίπεδο (ρίζα ή ίδιος parentId) — app-level έλεγχος του DAO.
  Future<int> create(CategoriesCompanion companion);

  /// Ενημέρωση κατηγορίας (full replace — πλήρες companion με id)
  Future<bool> update(CategoriesCompanion companion);

  /// Soft delete (isActive = false).
  /// Επιστρέφει false αν υπάρχουν ενεργά παιδιά (αποτροπή ορφανισμού δέντρου).
  Future<bool> softDelete(int id);
}