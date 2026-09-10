import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Suppliers table
/// ΑΦΜ: unique, nullable (μπορεί να μην έχει).
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get vatNumber => text().nullable().unique()();
  TextColumn get taxOffice => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get postalCode => text().nullable()();
  TextColumn get country => text().withDefault(const Constant('Ελλάδα'))();
  TextColumn get bankName => text().nullable()();
  TextColumn get bankAccount => text().nullable()();
  TextColumn get iban => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}
