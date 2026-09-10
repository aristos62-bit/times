import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';
import 'receipts.dart';
import 'items.dart';

/// SPO: Receipt items table (junction: receipt <-> items)
/// Κάθε γραμμή = ένα είδος μέσα σε μια απόδειξη.
class ReceiptItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptId => integer().references(Receipts, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
  RealColumn get vatRate => real().withDefault(const Constant(24.0))();
  RealColumn get vatAmount => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get totalPrice => real()();
  RealColumn get totalWithVat => real()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}
