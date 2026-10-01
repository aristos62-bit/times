/// Υλοποίηση `CategoryRepository` πάνω στον CategoryDao — Φάση 2, Βήμα 2.
///
/// Λεπτό repository layer (DESIGN §1.2, §4 Φάση 2): ΚΑΝΕΝΑ query logic —
/// όλα τα queries ζουν στα DAOs. Εδώ γίνεται ΜΟΝΟ το error-mapping μέσω
/// SPoT `guardRepo` (συμβόλαιο Βήμα 1).
///
/// Constructor με DAO μόνο (χωρίς AppDatabase — το `_dao.db` είναι public
/// final στο BaseDao, απόφαση Βήμα 2). Χωρίς logging εδώ: τα σφάλματα
/// λογκάρονται ήδη μία φορά από τον DAO guard.
library;

import '../../core/errors/app_exceptions.dart';
import '../local/daos/category_dao.dart';
import '../local/app_database.dart';
import 'category_repository.dart';
import 'repo_guard.dart';

/// Σκέτο mapping φουλ CRUD + stream του CategoryDao σε AppException.
final class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dao);

  final CategoryDao _dao;

  @override
  Stream<List<Category>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Future<Category?> getById(int id) => guardRepo(() => _dao.getById(id));

  @override
  Future<Category?> getByNormalizedName(String normalizedName) =>
      guardRepo(() => _dao.getByNormalizedName(normalizedName));

  @override
  Future<int> insert({required String name}) =>
      guardRepo(() => _dao.insert(name: name));

  @override
  Future<bool> updateById(int id, {required String name}) =>
      guardRepo(() => _dao.updateById(id, name: name));

  @override
  Future<bool> deleteById(int id) => guardRepo(() => _dao.deleteById(id));

  @override
  Future<int> countItemsInUse(int categoryId) =>
      guardRepo(() => _dao.countItemsInUseByCategoryId(categoryId));

  @override
  Future<int> countItems(int categoryId) =>
      guardRepo(() => _dao.countItemsByCategoryId(categoryId));

  @override
  Future<bool> deleteWithContents(int categoryId) =>
      guardRepo(() => _dao.deleteWithContents(categoryId));
}