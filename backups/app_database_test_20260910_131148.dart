import 'package:expense_tracker/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDatabase', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion είναι 1', () {
      expect(db.schemaVersion, 1);
    });

    test('δημιουργεί 8 default categories', () async {
      final count = await db.select(db.categories).get();
      expect(count.length, 8);
    });

    test('περιέχει Τρόφιμα', () async {
      final names = await db.select(db.categories).get();
      final namesList = names.map((r) => r.name).toList();
      expect(namesList, contains('Τρόφιμα'));
    });

    test('όλες οι categories είναι active', () async {
      final categories = await db.select(db.categories).get();
      for (final c in categories) {
        expect(c.isActive, isTrue);
      }
    });

    test('categories έχουν createdAt και updatedAt', () async {
      final categories = await db.select(db.categories).get();
      for (final c in categories) {
        expect(c.createdAt, isA<DateTime>());
        expect(c.updatedAt, isA<DateTime>());
      }
    });

    test('περιέχει theme_mode setting', () async {
      final settings = await db.select(db.userSettings).get();
      final keys = settings.map((r) => r.key).toList();
      expect(keys, contains('theme_mode'));
    });

    test('currency = €', () async {
      final currency = await (db.select(db.userSettings)
            ..where((s) => s.key.equals('currency')))
          .getSingleOrNull();
      expect(currency?.value, '€');
    });

    test('default_vat_rate = 24.0', () async {
      final vat = await (db.select(db.userSettings)
            ..where((s) => s.key.equals('default_vat_rate')))
          .getSingleOrNull();
      expect(vat?.value, '24.0');
    });

    test('PRAGMA foreign_keys ενεργό', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').get();
      expect(result.first.data['foreign_keys'], 1);
    });

    test('createdAt είναι local DateTime', () async {
      final categories = await db.select(db.categories).get();
      expect(categories.first.createdAt.isUtc, isFalse);
    });
  });
}
