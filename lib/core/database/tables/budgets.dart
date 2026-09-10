import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';
import 'categories.dart';

/// SPO: Budgets table
/// Κάθε budget ανήκει σε κατηγορία + μήνα/έτος.
/// NO spentAmount — το spent υπολογίζεται LIVE (§4.3 BudgetDao).
/// Unique key: (categoryId, month, year).
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [{categoryId, month, year}];
}
