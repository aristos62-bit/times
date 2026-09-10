import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/daos.dart';
import '../../domain/repositories/item_repository.dart';

/// SPO: Item Repository implementation (pure delegate).
///
/// Route A-Συνεπές: κάθε μέθοδος προωθεί 1:1 στον [ItemDao] — χωρίς
/// validation, χωρίς mapping, χωρίς StreamControllers. Ο DAO είναι ο μόνος
/// SPoT του data-access layer (Fix #2 increaseStock: UTC normalization).
/// Instantiation: constructor injection (DI έρχεται σε επόμενη φάση).
class ItemRepositoryImpl implements ItemRepository {
  /// Ο μόνος dependency του repository — ο item DAO.
  final ItemDao _dao;

  const ItemRepositoryImpl(this._dao);

  @override
  Stream<List<Item>> watchAll() => _dao.watchAllItems();

  @override
  Stream<List<Item>> watchByCategory(int categoryId) =>
      _dao.watchItemsByCategory(categoryId);

  @override
  Stream<List<Item>> watchByBarcode(String barcode) =>
      _dao.watchItemsByBarcode(barcode);

  @override
  Stream<List<Item>> searchByName(String query) =>
      _dao.searchItemsByName(query);

  @override
  Stream<List<Item>> watchLowStock() => _dao.watchLowStock();

  @override
  Future<Item?> getById(int id) => _dao.getItemById(id);

  @override
  Future<int> create(ItemsCompanion companion) => _dao.createItem(companion);

  @override
  Future<bool> update(ItemsCompanion companion) => _dao.updateItem(companion);

  @override
  Future<void> softDelete(int id) => _dao.softDeleteItem(id);

  @override
  Future<void> increaseStock(
    int itemId,
    double quantity, {
    double? unitPrice,
    int? supplierId,
  }) =>
      _dao.increaseStock(itemId, quantity,
          unitPrice: unitPrice, supplierId: supplierId);
}