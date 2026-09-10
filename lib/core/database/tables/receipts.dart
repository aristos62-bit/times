import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';
import 'suppliers.dart';

/// SPO: Receipts table
/// receiptNumber: unique sequential number (1,2,3...).
/// paymentStatus: 'pending' | 'partial' | 'paid'.
class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptNumber => integer().unique()();
  Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get invoiceSeries => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get vatTotal => real().withDefault(const Constant(0))();
  RealColumn get discountTotal => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}
