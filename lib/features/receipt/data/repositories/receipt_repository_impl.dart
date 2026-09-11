// features/receipt/data/repositories/receipt_repository_impl.dart
//
// SPO: Receipt Repository implementation (pure delegate).
//
// Route A-Συνεπές: κάθε μέθοδος προωθεί 1:1 στον [ReceiptDao]. Χωρίς
// validation, mapping ή StreamControllers. Ο DAO είναι ο μόνος SPoT του
// data-access layer (αρίθμηση counter, stock deltas, _refreshFinancials,
// aggregates §5.1.6). Exceptions προωθούνται ως έχουν (π.χ. SqliteException
// από FK violation) — δεν καταπνίγονται.
//
// Instantiation: constructor injection μέσω dependency_injection.dart.
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/daos.dart';
import '../../domain/models/receipt_input.dart';
import '../../domain/repositories/receipt_repository.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final ReceiptDao _receiptDao;

  const ReceiptRepositoryImpl(this._receiptDao);

  @override
  Stream<List<Receipt>> watchAll({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    String? paymentStatus,
  }) =>
      _receiptDao.watchAllReceipts(
        startDate: startDate,
        endDate: endDate,
        supplierId: supplierId,
        paymentStatus: paymentStatus,
      );

  @override
  Future<Receipt?> getById(int id) => _receiptDao.getReceiptById(id);

  @override
  Stream<List<ReceiptItem>> watchItemsByReceiptId(int receiptId) =>
      _receiptDao.watchReceiptItems(receiptId);

  @override
  Future<int> create(ReceiptInput input) =>
      _receiptDao.createReceipt(input);

  @override
  Future<void> updateItem(
    int receiptId,
    int itemId,
    ReceiptItemUpdate update,
  ) =>
      _receiptDao.updateReceiptItem(receiptId, itemId, update);

  @override
  Future<void> deleteItem(int receiptId, int itemId) =>
      _receiptDao.deleteReceiptItem(receiptId, itemId);

  @override
  Future<void> delete(int id) => _receiptDao.deleteReceipt(id);

  @override
  Future<int> getNextReceiptNumber() =>
      _receiptDao.getNextReceiptNumber();

  @override
  Stream<double> watchTotalByDateRange(DateTime start, DateTime end) =>
      _receiptDao.watchTotalByDateRange(start, end);

  @override
  Stream<Map<String, double>> watchTotalByCategory(
    DateTime start,
    DateTime end,
  ) =>
      _receiptDao.watchTotalByCategory(start, end);
}