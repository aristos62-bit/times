import 'package:expense_tracker/core/database/tables/utc_date_time_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UtcDateTimeConverter', () {
    const converter = UtcDateTimeConverter();

    group('toSql — αποθήκευση UTC', () {
      test('μετατρέπει local DateTime σε UTC', () {
        final local = DateTime(2026, 6, 15, 14, 30);
        final result = converter.toSql(local);

        expect(result.isUtc, isTrue);
        expect(result.year, 2026);
        expect(result.month, 6);
        expect(result.day, 15);
      });

      test('διατηρεί ακριβή ημερομηνία όταν ήδη UTC', () {
        final utc = DateTime.utc(2026, 12, 31, 23, 59, 59);
        final result = converter.toSql(utc);

        expect(result.isUtc, isTrue);
        expect(result, utc);
      });
    });

    group('fromSql — ανάγνωση local', () {
      test('μετατρέπει UTC DateTime σε local', () {
        final utcTime = DateTime.utc(2026, 6, 15, 12, 0);
        final result = converter.fromSql(utcTime);

        expect(result.isUtc, isFalse);
        expect(result.year, 2026);
        expect(result.month, 6);
        expect(result.day, 15);
      });
    });

    group('roundtrip — toSql -> fromSql', () {
      test('διατηρεί ημερομηνία μετά από roundtrip', () {
        final original = DateTime(2026, 7, 4, 10, 30);
        final sql = converter.toSql(original);
        final restored = converter.fromSql(sql);

        expect(restored.year, original.year);
        expect(restored.month, original.month);
        expect(restored.day, original.day);
        expect(restored.hour, original.hour);
        expect(restored.minute, original.minute);
      });

      test('roundtrip με UTC DateTime', () {
        final original = DateTime.utc(2026, 3, 15, 8, 0);
        final sql = converter.toSql(original);
        final restored = converter.fromSql(sql);

        expect(restored.year, original.year);
        expect(restored.month, original.month);
        expect(restored.day, original.day);
      });
    });

    test('constructor είναι const', () {
      const c1 = UtcDateTimeConverter();
      const c2 = UtcDateTimeConverter();
      expect(identical(c1, c2), isTrue);
    });
  });
}
