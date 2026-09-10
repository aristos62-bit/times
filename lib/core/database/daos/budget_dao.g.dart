// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_dao.dart';

// ignore_for_file: type=lint
mixin _$BudgetDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $BudgetsTable get budgets => attachedDatabase.budgets;
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $ReceiptsTable get receipts => attachedDatabase.receipts;
  $ItemsTable get items => attachedDatabase.items;
  $ReceiptItemsTable get receiptItems => attachedDatabase.receiptItems;
  BudgetDaoManager get managers => BudgetDaoManager(this);
}

class BudgetDaoManager {
  final _$BudgetDaoMixin _db;
  BudgetDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db.attachedDatabase, _db.budgets);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db.attachedDatabase, _db.receipts);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$ReceiptItemsTableTableManager get receiptItems =>
      $$ReceiptItemsTableTableManager(_db.attachedDatabase, _db.receiptItems);
}
