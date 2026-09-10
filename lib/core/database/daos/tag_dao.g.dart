// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_dao.dart';

// ignore_for_file: type=lint
mixin _$TagDaoMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $ReceiptsTable get receipts => attachedDatabase.receipts;
  $ReceiptTagsTable get receiptTags => attachedDatabase.receiptTags;
  TagDaoManager get managers => TagDaoManager(this);
}

class TagDaoManager {
  final _$TagDaoMixin _db;
  TagDaoManager(this._db);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db.attachedDatabase, _db.receipts);
  $$ReceiptTagsTableTableManager get receiptTags =>
      $$ReceiptTagsTableTableManager(_db.attachedDatabase, _db.receiptTags);
}
