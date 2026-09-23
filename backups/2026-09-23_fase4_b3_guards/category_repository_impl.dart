/// Υλοποίηση `CategoryRepository` πάνω στον CategoryDao — Φάση 2, Βήμα 2.
///
/// Λεπτό repository layer (DESIGN §1.2, §4 Φάση 2): ΚΑΝΕΝΑ query logic —
/// όλα τα queries ζουν στα DAOs. Εδώ γίνεται ΜΟΝΟ το error-mapping:
/// τα DAOs ρίχνουν raw `SqliteException` (BaseDao guard, §4.1) και το
/// repository mapάρει σε `DataLoadException` (συμβόλαιο Βήμα 1).
///
/// Constructor με DAO μόνο (χωρίς AppDatabase — το `_dao.db` είναι public
/// final στο BaseDao, απόφαση Βήμα 2). Χωρίς logging εδώ: τα σφάλματα
/// λογκάρονται ήδη μία φορά από τον DAO guard.
library;

import 'package:drift/native.dart';

import '../../core/errors/app_exceptions.dart';
import '../local/daos/category_dao.dart';
import '../local/app_database.dart';
import 'category_repository.dart';

/// Σκέτο mapping φουλ CRUD + stream του CategoryDao σε AppException.
final class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._dao);

  final CategoryDao _dao;

  /// Εκτελεί [op]· raw SqliteException → `DataLoadException`.
  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on SqliteException {
      throw const DataLoadException();
    }
  }

  @override
  Stream<List<Category>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Future<Category?> getById(int id) => _guard(() => _dao.getById(id));

  @override
  Future<int> insert({required String name}) =>
      _guard(() => _dao.insert(name: name));

  @override
  Future<bool> updateById(int id, {required String name}) =>
      _guard(() => _dao.updateById(id, name: name));

  @override
  Future<bool> deleteById(int id) => _guard(() => _dao.deleteById(id));
}