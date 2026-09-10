import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/daos.dart';
import '../../domain/repositories/category_repository.dart';

/// SPO: Category Repository implementation (pure delegate).
///
/// Route A-Συνεπές: κάθε μέθοδος προωθεί 1:1 στον [CategoryDao] — χωρίς
/// validation, χωρίς mapping, χωρίς StreamControllers. Ο DAO είναι ο μόνος
/// SPoT του data-access layer (Fix #4 softDelete: blocks orphan children).
/// Το [create] προωθεί αβίαστα το [CategoryDuplicateNameException] του DAO
/// (category_dao.dart:128-135) — ο caller το χειρίζεται.
/// Instantiation: constructor injection (DI έρχεται σε επόμενη φάση).
class CategoryRepositoryImpl implements CategoryRepository {
  /// Ο μόνος dependency του repository — ο category DAO.
  final CategoryDao _dao;

  const CategoryRepositoryImpl(this._dao);

  @override
  Stream<List<Category>> watchAll() => _dao.watchAllCategories();

  @override
  Stream<List<Category>> watchTree() => _dao.watchCategoryTree();

  @override
  Stream<List<Category>> watchWithChildrenRecursively(int rootId) =>
      _dao.watchCategoryWithChildrenRecursively(rootId);

  @override
  Future<Category?> getById(int id) => _dao.getCategoryById(id);

  @override
  Future<int> create(CategoriesCompanion companion) =>
      _dao.createCategory(companion);

  @override
  Future<bool> update(CategoriesCompanion companion) =>
      _dao.updateCategory(companion);

  @override
  Future<bool> softDelete(int id) => _dao.softDeleteCategory(id);
}