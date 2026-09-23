/// Υλοποίηση `SubCategoryRepository` πάνω στον SubCategoryDao — Φάση 2, Βήμα 2.
///
/// Λεπτό repository layer: μηδέν query logic — όλα στα DAOs. Μόνο
/// error-mapping raw `SqliteException` → `DataLoadException` (συμβόλαιο
/// Βήμα 1). Χωρίς logging (ήδη από τον DAO guard).
library;

import 'package:drift/native.dart';

import '../../core/errors/app_exceptions.dart';
import '../local/daos/sub_category_dao.dart';
import '../local/app_database.dart';
import 'sub_category_repository.dart';

/// Υλοποίηση με mapping + stream passthrough με handleError.
final class SubCategoryRepositoryImpl implements SubCategoryRepository {
  SubCategoryRepositoryImpl(this._dao);

  final SubCategoryDao _dao;

  /// Εκτελεί [op]· raw SqliteException → `DataLoadException`.
  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on SqliteException {
      throw const DataLoadException();
    }
  }

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
  Future<SubCategory?> getById(int id) => _guard(() => _dao.getById(id));

  @override
  Future<int> insert({required int categoryId, required String name}) =>
      _guard(() => _dao.insert(categoryId: categoryId, name: name));

  @override
  Future<bool> updateById(int id, {int? categoryId, String? name}) =>
      _guard(() => _dao.updateById(id, categoryId: categoryId, name: name));

  @override
  Future<bool> deleteById(int id) => _guard(() => _dao.deleteById(id));
}