import 'package:drift/drift.dart';
import 'utc_date_time_converter.dart';

/// SPO: User settings table (key-value store)
/// SPoT αποθήκευσης ρυθμίσεων (π.χ. theme).
/// Unique: key (global).
/// ΚΑΝΕΝΑ SharedPreferences για theme.
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('string'))();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}
