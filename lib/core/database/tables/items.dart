import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';
import 'categories.dart';
import 'suppliers.dart';

/// SPO: Items table
/// FK: categoryId (required), lastSupplierId/preferredSupplierId (optional).
/// Unique key: (name, categoryId) — μοναδικό όνομα ανά κατηγορία.
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('τεμ'))();
  RealColumn get unitWeight => real().nullable()();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get maxStock => real().withDefault(const Constant(0))();
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0))();
  RealColumn get lastPrice => real().nullable()();
  IntColumn get lastSupplierId => integer().references(Suppliers, #id).nullable()();
  IntColumn get preferredSupplierId => integer().references(Suppliers, #id).nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isTaxable => boolean().withDefault(const Constant(true))();
  RealColumn get defaultVatRate => real().withDefault(const Constant(24.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [{name, categoryId}];
}
