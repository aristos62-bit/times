import 'package:drift/drift.dart';
import 'receipts.dart';
import 'tags.dart';

/// SPO: Receipt tags junction table (receipt <-> tags)
/// Composite primary key: (receiptId, tagId).
/// Δεν έχει uuid — junction table, όχι entity.
class ReceiptTags extends Table {
  IntColumn get receiptId => integer().references(Receipts, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {receiptId, tagId};
}
