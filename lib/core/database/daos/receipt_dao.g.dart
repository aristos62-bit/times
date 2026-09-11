// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_dao.dart';

// ignore_for_file: type=lint
mixin _$ReceiptDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $ReceiptsTable get receipts => attachedDatabase.receipts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ItemsTable get items => attachedDatabase.items;
  $ReceiptItemsTable get receiptItems => attachedDatabase.receiptItems;
  $PaymentsTable get payments => attachedDatabase.payments;
  $PriceHistoryTable get priceHistory => attachedDatabase.priceHistory;
  ReceiptDaoManager get managers => ReceiptDaoManager(this);
}

class ReceiptDaoManager {
  final _$ReceiptDaoMixin _db;
  ReceiptDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db.attachedDatabase, _db.receipts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$ReceiptItemsTableTableManager get receiptItems =>
      $$ReceiptItemsTableTableManager(_db.attachedDatabase, _db.receiptItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
  $$PriceHistoryTableTableManager get priceHistory =>
      $$PriceHistoryTableTableManager(_db.attachedDatabase, _db.priceHistory);
}
