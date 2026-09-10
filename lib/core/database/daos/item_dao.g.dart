// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_dao.dart';

// ignore_for_file: type=lint
mixin _$ItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $ItemsTable get items => attachedDatabase.items;
  $ReceiptsTable get receipts => attachedDatabase.receipts;
  $ReceiptItemsTable get receiptItems => attachedDatabase.receiptItems;
  $PriceHistoryTable get priceHistory => attachedDatabase.priceHistory;
  ItemDaoManager get managers => ItemDaoManager(this);
}

class ItemDaoManager {
  final _$ItemDaoMixin _db;
  ItemDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db.attachedDatabase, _db.receipts);
  $$ReceiptItemsTableTableManager get receiptItems =>
      $$ReceiptItemsTableTableManager(_db.attachedDatabase, _db.receiptItems);
  $$PriceHistoryTableTableManager get priceHistory =>
      $$PriceHistoryTableTableManager(_db.attachedDatabase, _db.priceHistory);
}
