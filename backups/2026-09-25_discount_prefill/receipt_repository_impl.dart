/// Υλοποίηση `ReceiptRepository` πάνω σε ReceiptDao + ReceiptLineDao —
/// Φάση 2, Βήμα 2.
///
/// Λεπτό repository layer (μηδέν query logic). Εκτός από το standard
/// mapping σε `DataLoadException` (reads), το `insertReceiptWithLines`
/// εκτελεί κεφαλίδα + γραμμές σε ΜΙΑ drift transaction (atomicity §3):
/// αποτυχία → rollback + `SaveReceiptException` (συμβόλαιο Βήμα 1).
///
/// Το lineTotalCents υπολογίζεται στο ReceiptLineDao (SPoT §3) — εδώ
/// περνάνε μόνο τα βασικά πεδία (ReceiptLineInput). Χωρίς logging εδώ:
/// οι DAO guards λογκάρουν ήδη τις αποτυχίες μέσα στη transaction.
library;

import 'package:drift/native.dart';

import '../../core/errors/app_exceptions.dart';
import '../local/daos/receipt_dao.dart';
import '../local/daos/receipt_line_dao.dart';
import '../local/app_database.dart';
import '../models/receipt_summary.dart';
import 'receipt_repository.dart';

/// Υλοποίηση με δύο DAOs (κεφαλίδα + γραμμές) και transaction save.
final class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl(this._receiptDao, this._lineDao);

  final ReceiptDao _receiptDao;
  final ReceiptLineDao _lineDao;

  /// Εκτελεί [op]· raw SqliteException → `DataLoadException`.
  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on SqliteException {
      throw const DataLoadException();
    }
  }

  @override
  Stream<List<Receipt>> watchAll() => _receiptDao.watchAll().handleError(
        (Object e, StackTrace s) =>
            Error.throwWithStackTrace(const DataLoadException(), s),
      );

  @override
  Stream<List<ReceiptSummary>> watchRecentSummaries({required int limit}) =>
      _receiptDao.watchRecentSummaries(limit: limit).handleError(
            (Object e, StackTrace s) =>
                Error.throwWithStackTrace(const DataLoadException(), s),
          );

  @override
  Stream<List<ReceiptSummary>> watchSummariesByDay({
    required DateTime day,
    required int limit,
  }) =>
      _receiptDao.watchSummariesByDay(day: day, limit: limit).handleError(
            (Object e, StackTrace s) =>
                Error.throwWithStackTrace(const DataLoadException(), s),
          );

  @override
  Future<Receipt?> getById(int id) => _guard(() => _receiptDao.getById(id));

  @override
  Future<int> countBySupplierId(int supplierId) =>
      _guard(() => _receiptDao.countBySupplierId(supplierId));

  @override
  Future<int> insert({required DateTime date, required int supplierId}) =>
      _guard(() => _receiptDao.insert(date: date, supplierId: supplierId));

  @override
  Future<bool> updateById(int id, {DateTime? date, int? supplierId}) =>
      _guard(() => _receiptDao.updateById(id, date: date, supplierId: supplierId));

  @override
  Future<bool> deleteById(int id) => _guard(() => _receiptDao.deleteById(id));

  @override
  Stream<List<ReceiptLine>> watchLines(int receiptId) =>
      _lineDao.watchByReceiptId(receiptId).handleError(
            (Object e, StackTrace s) =>
                Error.throwWithStackTrace(const DataLoadException(), s),
          );

  @override
  Future<List<ReceiptLine>> getLines(int receiptId) =>
      _guard(() => _lineDao.getByReceiptId(receiptId));

  @override
  Future<int> insertReceiptWithLines({
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  }) async {
    try {
      return await _receiptDao.db.transaction(() async {
        final receiptId =
            await _receiptDao.insert(date: date, supplierId: supplierId);
        for (final line in lines) {
          await _lineDao.insert(
            receiptId: receiptId,
            itemId: line.itemId,
            unitId: line.unitId,
            quantity: line.quantity,
            priceCents: line.priceCents,
          );
        }
        return receiptId;
      });
    } on SqliteException {
      // Rollback automatic (drift) — αναδύεται μόνο το mapped exception.
      throw const SaveReceiptException();
    }
  }

  @override
  Future<void> updateReceiptWithLines({
    required int id,
    required DateTime date,
    required int supplierId,
    required List<ReceiptLineInput> lines,
  }) async {
    try {
      await _receiptDao.db.transaction(() async {
        final updated = await _receiptDao.updateById(
          id,
          date: date,
          supplierId: supplierId,
        );
        if (!updated) throw const DataLoadException();
        await (_receiptDao.db.delete(_receiptDao.db.receiptLines)
              ..where((t) => t.receiptId.equals(id)))
            .go();
        for (final line in lines) {
          await _lineDao.insert(
            receiptId: id,
            itemId: line.itemId,
            unitId: line.unitId,
            quantity: line.quantity,
            priceCents: line.priceCents,
          );
        }
      });
    } on DataLoadException {
      rethrow;
    } on SqliteException {
      // Rollback automatic (drift) — αναδύεται μόνο το mapped exception.
      throw const SaveReceiptException();
    }
  }
}