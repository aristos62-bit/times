import 'package:drift/drift.dart';

/// SPoT: UTC TypeConverter — ΕΠΙΒΑΛΛΕΙ την timezone policy στον κώδικα.
/// Αποθήκευση: πάντα UTC. Ανάγνωση: πάντα local timezone.
/// Με `storeDateTimeAsText: true`, ο drift διαχειρίζεται το DateTime↔String.
/// Αυτός ο converter χειρίζεται ΜΟΝΟ το UTC↔local timezone conversion.
class UtcDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const UtcDateTimeConverter();
  @override
  DateTime fromSql(DateTime fromDb) => fromDb.toLocal();
  @override
  DateTime toSql(DateTime value) => value.toUtc();
}
