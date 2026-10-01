/// Υλοποίηση `UnitRepository` πάνω στον UnitDao — Φάση 2, Βήμα 2.
///
/// Λεπτό repository layer: μηδέν query logic — μόνο error-mapping μέσω
/// SPoT `guardRepo` (συμβόλαιο Βήμα 1). Το deleteById mapάρει και το
/// RESTRICT (ReceiptLines.unitId) σε `DataLoadException` — βλ. docstring
/// interface (διόρθωση Βήμα 2).
/// Χωρίς logging (ήδη από τον DAO guard).
library;

import '../../core/errors/app_exceptions.dart';
import '../local/daos/unit_dao.dart';
import '../local/app_database.dart';
import 'repo_guard.dart';
import 'unit_repository.dart';

/// Full CRUD + stream mapping του UnitDao σε AppException.
final class UnitRepositoryImpl implements UnitRepository {
  UnitRepositoryImpl(this._dao);

  final UnitDao _dao;

  @override
  Stream<List<Unit>> watchAll() => _dao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Future<Unit?> getById(int id) => guardRepo(() => _dao.getById(id));

  @override
  Future<int> insert({
    required String name,
    required String abbreviation,
    bool allowsDecimal = false,
  }) =>
      guardRepo(
        () => _dao.insert(
          name: name,
          abbreviation: abbreviation,
          allowsDecimal: allowsDecimal,
        ),
      );

  @override
  Future<bool> updateById(
    int id, {
    String? name,
    String? abbreviation,
    bool? allowsDecimal,
  }) =>
      guardRepo(
        () => _dao.updateById(
          id,
          name: name,
          abbreviation: abbreviation,
          allowsDecimal: allowsDecimal,
        ),
      );

  @override
  Future<bool> deleteById(int id) => guardRepo(() => _dao.deleteById(id));
}