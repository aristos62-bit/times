import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';
import 'receipts.dart';

/// SPO: Payments table
/// Κάθε πληρωμή ανήκει σε μια απόδειξη.
/// Μπορεί να υπάρχουν πολλές πληρωμές (partial payments).
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptId => integer().references(Receipts, #id)();
  RealColumn get amount => real()();
  Column<DateTime> get paymentDate => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get paymentMethod => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}
