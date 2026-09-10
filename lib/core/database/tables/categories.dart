import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Categories table
/// Κάθε κατηγορία μπορεί να έχει parent (tree structure).
/// Unique key: (name, parentId) — μοναδικό όνομα ανά parent.
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get parentId => integer().references(Categories, #id).nullable()();
  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdBy => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();

  @override
  List<Set<Column>> get uniqueKeys => [{name, parentId}];
}
