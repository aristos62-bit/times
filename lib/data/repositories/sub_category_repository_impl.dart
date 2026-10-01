/// Υλοποίηση `SubCategoryRepository` πάνω στον SubCategoryDao — Φάση 2, Βήμα 2.
///
/// Λεπτό repository layer: μηδέν query logic — όλα στα DAOs. Μόνο
/// error-mapping μέσω SPoT `guardRepo` (συμβόλαιο Βήμα 1). Χωρίς logging
/// (ήδη από τον DAO guard).
library;

import '../../core/errors/app_exceptions.dart';
import '../local/daos/sub_category_dao.dart';
import '../local/app_database.dart';
import 'repo_guard.dart';
import 'sub_category_repository.dart';

/// Υλοποίηση με mapping + stream passthrough με handleError.
final class SubCategoryRepositoryImpl implements SubCategoryRepository {
  SubCategoryRepositoryImpl(this._dao);

  final SubCategoryDao _dao;

  @override
  Stream<List<SubCategory>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Stream<List<SubCategory>> watchByCategoryId(int categoryId) =>
      _dao.watchByCategoryId(categoryId).handleError(
            (Object e, StackTrace s) =>
                Error.throwWithStackTrace(const DataLoadException(), s),
          );

  @override
  Future<SubCategory?> getById(int id) => guardRepo(() => _dao.getById(id));

  @override
  Future<SubCategory?> getByNormalizedName(String normalizedName) =>
      guardRepo(() => _dao.getByNormalizedName(normalizedName));

  @override
  Future<int> insert({required int categoryId, required String name}) =>
      guardRepo(() => _dao.insert(categoryId: categoryId, name: name));

  @override
  Future<bool> updateById(int id, {int? categoryId, String? name}) =>
      guardRepo(() => _dao.updateById(id, categoryId: categoryId, name: name));

  @override
  Future<bool> deleteById(int id) => guardRepo(() => _dao.deleteById(id));

  @override
  Future<int> countItemsInUse(int subCategoryId) =>
      guardRepo(() => _dao.countItemsInUseBySubCategoryId(subCategoryId));

  @override
  Future<int> countItems(int subCategoryId) =>
      guardRepo(() => _dao.countItemsBySubCategoryId(subCategoryId));

  @override
  Future<bool> deleteWithContents(int subCategoryId) =>
      guardRepo(() => _dao.deleteWithContents(subCategoryId));
}