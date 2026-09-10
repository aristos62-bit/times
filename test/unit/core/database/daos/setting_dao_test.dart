import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingDao', () {
    late AppDatabase db;
    late SettingDao dao;

    setUp(() async {
      db = AppDatabase.test();
      dao = SettingDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('getThemeMode: seed theme_mode=0 → system', () async {
      expect(await dao.getThemeMode(), ThemeMode.system);
    });

    test('setThemeMode + getThemeMode roundtrip (dark)', () async {
      await dao.setThemeMode(ThemeMode.dark);
      expect(await dao.getThemeMode(), ThemeMode.dark);
    });

    test('setThemeMode → watchThemeMode emits (reactive)', () async {
      final stream = dao.watchThemeMode();
      final first = await stream.first;
      await dao.setThemeMode(ThemeMode.light);
      final second = await stream.first;
      expect(first, ThemeMode.system);
      expect(second, ThemeMode.light);
    });

    test('getSetting: missing key → null', () async {
      expect(await dao.getSetting('not_exist'), isNull);
    });

    test('setSetting upsert: μία μόνο γραμμή ανά key', () async {
      await dao.setSetting('currency', 'USD');
      await dao.setSetting('currency', 'GBP');

      final rows = await db.select(db.userSettings).get();
      final currency = rows.where((s) => s.key == 'currency').toList();
      expect(currency.length, 1);
      expect(currency.single.value, 'GBP');
    });

    test('setSetting with type', () async {
      await dao.setSetting('my_key', '42', type: 'int');
      final row = await (db.select(db.userSettings)
            ..where((s) => s.key.equals('my_key')))
          .getSingle();
      expect(row.value, '42');
      expect(row.type, 'int');
    });

    test('watchSetting: initial value από seed + emits σε αλλαγή', () async {
      final stream = dao.watchSetting('currency');
      expect(await stream.first, '€');
      await dao.setSetting('currency', 'USD');
      expect(await stream.first, 'USD');
    });

    test('_parseThemeMode μέσω getThemeMode: άκυρη τιμή → system', () async {
      await dao.setSetting('theme_mode', '99');
      expect(await dao.getThemeMode(), ThemeMode.system);
    });
  });
}