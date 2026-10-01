/// Υλοποίηση `SupplierRepository` πάνω στον SupplierDao — Φάση 2, Βήμα 2.
///
/// Λεπτό repository layer + αναζήτηση `searchByNormalizedName` (LIKE στο
/// `normalizedName` μέσω `_dao.db` — DESIGN §4 Φάση 2). Ίδιο μοτίβο με
/// ItemRepositoryImpl: input ήδη-normalized, `escapeLike` + `escapeChar`
/// στο drift `like()`, mapping σε `DataLoadException`. Χωρίς logging
/// (ήδη από τον DAO guard).
library;

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/greek_text_normalizer.dart';
import '../local/daos/supplier_dao.dart';
import '../local/app_database.dart';
import 'supplier_repository.dart';

/// Full CRUD + LIKE search του SupplierDao με mapping σε AppException.
final class SupplierRepositoryImpl implements SupplierRepository {
  SupplierRepositoryImpl(this._dao);

  final SupplierDao _dao;

  /// Εκτελεί [op]· raw SqliteException → `DataLoadException`.
  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on SqliteException {
      throw const DataLoadException();
    }
  }

  @override
  Stream<List<Supplier>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Stream<List<Supplier>> searchByNormalizedName(String query, {int? limit}) {
    // Κενό query → άμεση κενή λίστα (δεν πυροδοτείται stream query στη βάση).
    if (query.isEmpty) return Stream.value(const []);

    final resolvedLimit = limit == null || limit <= 0
        ? AppConstants.searchResultsLimit
        : limit;
    final pattern = '%${GreekTextNormalizer.escapeLike(query)}%';

    return (_dao.db.select(_dao.db.suppliers)
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
  Future<Supplier?> getById(int id) => _guard(() => _dao.getById(id));

  @override
  Future<Supplier?> getByNormalizedName(String normalizedName) =>
      _guard(() => _dao.getByNormalizedName(normalizedName));

  @override
  Future<int> insert({required String name}) =>
      _guard(() => _dao.insert(name: name));

  @override
  Future<bool> updateById(int id, {required String name}) =>
      _guard(() => _dao.updateById(id, name: name));

  @override
  Future<bool> deleteById(int id) => _guard(() => _dao.deleteById(id));
}