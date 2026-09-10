import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tables.dart';

part 'item_dao.g.dart';

/// SPO: Item Data Access Object
@DriftAccessor(tables: [Items, Categories, Suppliers, ReceiptItems, PriceHistory])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  /// Watch all active items (reactive)
  Stream<List<Item>> watchAllItems() {
    return (select(items)
          ..where((i) => i.isActive.equals(true))
          ..orderBy([(i) => OrderingTerm.asc(i.name)]))
        .watch();
  }

  /// Watch items by category (reactive)
  Stream<List<Item>> watchItemsByCategory(int categoryId) {
    return (select(items)
          ..where((i) =>
              i.isActive.equals(true) & i.categoryId.equals(categoryId))
          ..orderBy([(i) => OrderingTerm.asc(i.name)]))
        .watch();
  }

  /// Watch items by barcode (reactive, exact match)
  Stream<List<Item>> watchItemsByBarcode(String barcode) {
    return (select(items)..where((i) => i.barcode.equals(barcode))).watch();
  }

  /// Search items by name (LIKE, reactive)
  Stream<List<Item>> searchItemsByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(items)
          ..where(
              (i) => i.isActive.equals(true) & i.name.lower().like(pattern))
          ..orderBy([(i) => OrderingTerm.asc(i.name)]))
        .watch();
  }

  /// Watch low-stock items (reorderLevel > 0 AND currentStock <= reorderLevel)
  Stream<List<Item>> watchLowStock() {
    return (select(items)
          ..where((i) =>
              i.isActive.equals(true) &
              i.reorderLevel.isBiggerThanValue(0) &
              i.currentStock.isSmallerOrEqual(i.reorderLevel))
          ..orderBy([(i) => OrderingTerm.asc(i.currentStock)]))
        .watch();
  }

  /// Get item by id
  Future<Item?> getItemById(int id) =>
      (select(items)..where((i) => i.id.equals(id))).getSingleOrNull();

  /// Create item
  Future<int> createItem(ItemsCompanion companion) =>
      into(items).insert(companion);

  /// Update item (full replace — caller must provide the full companion with id)
  Future<bool> updateItem(ItemsCompanion companion) =>
      update(items).replace(companion);

  /// Soft delete (isActive = false)
  Future<void> softDeleteItem(int id) async {
    await (update(items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Αύξηση stock (π.χ. κατά καταχώρηση απόδειξης).
  /// Atomic: `currentStock = currentStock + quantity`.
  Future<void> increaseStock(
    int itemId,
    double quantity, {
    double? unitPrice,
    int? supplierId,
  }) async {
    await (update(items)..where((i) => i.id.equals(itemId))).write(
      ItemsCompanion.custom(
        currentStock: items.currentStock + Variable<double>(quantity),
        lastPrice: unitPrice == null ? null : Variable<double>(unitPrice),
        lastSupplierId:
            supplierId == null ? null : Variable<int>(supplierId),
        updatedAt: Variable<DateTime>(DateTime.now()),
      ),
    );
  }
}
