// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_dao.dart';

// ignore_for_file: type=lint
mixin _$SupplierDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $ReceiptsTable get receipts => attachedDatabase.receipts;
  SupplierDaoManager get managers => SupplierDaoManager(this);
}

class SupplierDaoManager {
  final _$SupplierDaoMixin _db;
  SupplierDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db.attachedDatabase, _db.receipts);
}
