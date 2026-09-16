/// Υλοποίηση `ItemRepository` πάνω στον ItemDao — Φάση 2, Βήμα 2.
///
/// Πέρα από το standard error-mapping (raw `SqliteException` →
/// `DataLoadException`), εδώ ζει η αναζήτηση `searchByNormalizedName`:
/// LIKE στο `normalizedName` μέσω `_dao.db` (μόνιμη απόφαση: η αναζήτηση
/// ορίζεται στα Repositories, όχι στα DAOs — DESIGN §4 Φάση 2).
///
/// Το query build γίνεται με `_dao.db.items` ώστε ο mapping να μένει στο
/// repository ενώ το LIKE χτίζεται με drift query builder. Το input είναι
/// ήδη normalized (σύμβαση interface) και τα wildcards `%`/`_`/`\`
/// εξάγονται με `GreekTextNormalizer.escapeLike` + `escapeChar: r'\'` στο
/// `like()` (drift 2.35 παράγει `LIKE ? ESCAPE '\'`).
///
/// Χωρίς logging (τα σφάλματα λογκάρει ήδη ο DAO guard).
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/greek_text_normalizer.dart';
import '../local/daos/item_dao.dart';
import '../local/app_database.dart';
import 'item_repository.dart';

/// Full CRUD + LIKE search του ItemDao με mapping σε AppException.
final class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._dao);

  final ItemDao _dao;

  /// Εκτελεί [op]· raw SqliteException → `DataLoadException`.
  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on SqliteException {
      throw const DataLoadException();
    }
  }

  @override
  Stream<List<Item>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Stream<List<Item>> watchBySubCategoryId(int subCategoryId) =>
      _dao.watchBySubCategoryId(subCategoryId).handleError(
            (Object e, StackTrace s) =>
                Error.throwWithStackTrace(const DataLoadException(), s),
          );

  @override
  Stream<List<Item>> searchByNormalizedName(String query, {int? limit}) {
    // Κενό query → άμεση κενή λίστα (δεν πυροδοτείται stream query στη βάση).
    if (query.isEmpty) return Stream.value(const []);

    final resolvedLimit = limit == null || limit <= 0
        ? AppConstants.searchResultsLimit
        : limit;
    final pattern = '%${GreekTextNormalizer.escapeLike(query)}%';

    return (_dao.db.select(_dao.db.items)
          ..where((t) => t.normalizedName.like(pattern, escapeChar: r'\'))
          ..orderBy([(t) => OrderingTerm.asc(t.normalizedName)])
          ..limit(resolvedLimit))
        .watch()
        .handleError(
          (Object e, StackTrace s) =>
              Error.throwWithStackTrace(const DataLoadException(), s),
        );
  }

  @override
  Future<Item?> getById(int id) => _guard(() => _dao.getById(id));

  @override
  Future<Item?> getByNormalizedName(String normalizedName) =>
      _guard(() => _dao.getByNormalizedName(normalizedName));

  @override
  Future<int> insert({
    required int subCategoryId,
    required String name,
    int? defaultUnitId,
  }) =>
      _guard(
        () => _dao.insert(
          subCategoryId: subCategoryId,
          name: name,
          defaultUnitId: defaultUnitId,
        ),
      );

  @override
  Future<bool> updateById(
    int id, {
    int? subCategoryId,
    String? name,
    Value<int?>? defaultUnitId,
  }) =>
      _guard(
        () => _dao.updateById(
          id,
          subCategoryId: subCategoryId,
          name: name,
          defaultUnitId: defaultUnitId,
        ),
      );

  @override
  Future<bool> deleteById(int id) => _guard(() => _dao.deleteById(id));
}