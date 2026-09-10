import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';
import 'items.dart';
import 'suppliers.dart';

/// SPO: Price history table
/// Καταγράφει κάθε αγορά είδους για ιστορικό τιμών.
class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get itemId => integer().references(Items, #id)();
  RealColumn get price => real()();
  RealColumn get vatRate => real().withDefault(const Constant(24.0))();
  Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}
