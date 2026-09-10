import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Tags table
/// Ελεύθερα tags για receipts (π.χ. "επίσημο", "προσωπικό").
/// Unique: name (global — ένα tag όνομα υπάρχει μία φορά).
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}
