/// Υλοποίηση `ItemRepository` πάνω στον ItemDao — Φάση 2, Βήμα 2.
///
/// Πέρα από το standard error-mapping (SPoT `guardRepo`), εδώ ζει η
/// αναζήτηση `searchByNormalizedName`:
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

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/greek_text_normalizer.dart';
import '../local/daos/item_dao.dart';
import '../local/app_database.dart';
import 'item_repository.dart';
import 'repo_guard.dart';

/// Full CRUD + LIKE search του ItemDao με mapping σε AppException.
final class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._dao);

  final ItemDao _dao;

  @override
  Stream<List<Item>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Stream<List<Item>> watchByItemGroupId(int itemGroupId) =>
      _dao.watchByItemGroupId(itemGroupId).handleError(
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
  Future<Item?> getById(int id) => guardRepo(() => _dao.getById(id));

  @override
  Future<Item?> getByNormalizedName(String normalizedName) =>
      guardRepo(() => _dao.getByNormalizedName(normalizedName));

  @override
  Future<int> insert({
    required int itemGroupId,
    required String name,
    int? defaultUnitId,
  }) =>
      guardRepo(
        () => _dao.insert(
          itemGroupId: itemGroupId,
          name: name,
          defaultUnitId: defaultUnitId,
        ),
      );

  @override
  Future<bool> updateById(
    int id, {
    int? itemGroupId,
    String? name,
    Value<int?>? defaultUnitId,
  }) =>
      guardRepo(
        () => _dao.updateById(
          id,
          itemGroupId: itemGroupId,
          name: name,
          defaultUnitId: defaultUnitId,
        ),
      );

  @override
  Future<bool> deleteById(int id) => guardRepo(() => _dao.deleteById(id));
}