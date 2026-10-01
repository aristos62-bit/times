/// Υλοποίηση `ItemGroupRepository` πάνω στον ItemGroupDao — 27-09-2026.
///
/// Λεπτό repository layer (pattern `SubCategoryRepositoryImpl`): μηδέν
/// query logic — μόνο error-mapping μέσω SPoT `guardRepo`. Χωρίς logging
/// (ήδη από τον DAO guard).
library;

import '../../core/errors/app_exceptions.dart';
import '../local/daos/item_group_dao.dart';
import '../local/app_database.dart';
import 'item_group_repository.dart';
import 'repo_guard.dart';

/// Υλοποίηση με mapping + stream passthrough με handleError.
final class ItemGroupRepositoryImpl implements ItemGroupRepository {
  ItemGroupRepositoryImpl(this._dao);

  final ItemGroupDao _dao;

  @override
  Stream<List<ItemGroup>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Stream<List<ItemGroup>> watchBySubCategoryId(int subCategoryId) =>
      _dao.watchBySubCategoryId(subCategoryId).handleError(
            (Object e, StackTrace s) =>
                Error.throwWithStackTrace(const DataLoadException(), s),
          );

  @override
  Future<ItemGroup?> getById(int id) => guardRepo(() => _dao.getById(id));

  @override
  Future<ItemGroup?> getByNormalizedName(String normalizedName) =>
      guardRepo(() => _dao.getByNormalizedName(normalizedName));

  @override
  Future<int> insert({required int subCategoryId, required String name}) =>
      guardRepo(() => _dao.insert(subCategoryId: subCategoryId, name: name));

  @override
  Future<bool> updateById(int id, {int? subCategoryId, String? name}) =>
      guardRepo(
          () => _dao.updateById(id, subCategoryId: subCategoryId, name: name));

  @override
  Future<bool> deleteById(int id) => guardRepo(() => _dao.deleteById(id));

  @override
  Future<int> countItemsInUse(int itemGroupId) =>
      guardRepo(() => _dao.countItemsInUseByItemGroupId(itemGroupId));

  @override
  Future<int> countItems(int itemGroupId) =>
      guardRepo(() => _dao.countItemsByItemGroupId(itemGroupId));

  @override
  Future<bool> deleteWithContents(int itemGroupId) =>
      guardRepo(() => _dao.deleteWithContents(itemGroupId));
}
