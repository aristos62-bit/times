/// Υλοποίηση `ItemGroupRepository` πάνω στον ItemGroupDao — 27-09-2026.
///
/// Λεπτό repository layer (pattern `SubCategoryRepositoryImpl`): μηδέν
/// query logic — μόνο error-mapping raw `SqliteException` →
/// `DataLoadException`. Χωρίς logging (ήδη από τον DAO guard).
library;

import 'package:drift/native.dart';

import '../../core/errors/app_exceptions.dart';
import '../local/daos/item_group_dao.dart';
import '../local/app_database.dart';
import 'item_group_repository.dart';

/// Υλοποίηση με mapping + stream passthrough με handleError.
final class ItemGroupRepositoryImpl implements ItemGroupRepository {
  ItemGroupRepositoryImpl(this._dao);

  final ItemGroupDao _dao;

  /// Εκτελεί [op]· raw SqliteException → `DataLoadException`.
  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on SqliteException {
      throw const DataLoadException();
    }
  }

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
  Future<ItemGroup?> getById(int id) => _guard(() => _dao.getById(id));

  @override
  Future<ItemGroup?> getByNormalizedName(String normalizedName) =>
      _guard(() => _dao.getByNormalizedName(normalizedName));

  @override
  Future<int> insert({required int subCategoryId, required String name}) =>
      _guard(() => _dao.insert(subCategoryId: subCategoryId, name: name));

  @override
  Future<bool> updateById(int id, {int? subCategoryId, String? name}) =>
      _guard(
          () => _dao.updateById(id, subCategoryId: subCategoryId, name: name));

  @override
  Future<bool> deleteById(int id) => _guard(() => _dao.deleteById(id));

  @override
  Future<int> countItemsInUse(int itemGroupId) =>
      _guard(() => _dao.countItemsInUseByItemGroupId(itemGroupId));

  @override
  Future<int> countItems(int itemGroupId) =>
      _guard(() => _dao.countItemsByItemGroupId(itemGroupId));

  @override
  Future<bool> deleteWithContents(int itemGroupId) =>
      _guard(() => _dao.deleteWithContents(itemGroupId));
}
