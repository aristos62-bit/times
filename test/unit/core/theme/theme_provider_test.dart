// test/unit/core/theme/theme_provider_test.dart
//
// Επαληθεύει τη σύνδεση ThemeProvider ↔ SettingDao (Phase 2 Step 3):
// persistence στη βάση (user_settings), reactive stream, toggle.
// Το SettingDao περνιέται με AppDatabase.test() (in-memory) — χωρίς
// πραγματικό dependency στο global singleton database.
import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/daos/daos.dart';
import 'package:expense_tracker/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeProvider (SettingDao-backed)', () {
    late AppDatabase db;
    late SettingDao dao;
    late ThemeProvider provider;

    setUp(() async {
      db = AppDatabase.test();
      dao = SettingDao(db);
      provider = ThemeProvider(settingsDao: dao);
    });

    tearDown(() async {
      await db.close();
    });

    test('initialize: χωρίς αποθηκευμένο → system', () async {
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.initialize();
      expect(provider.themeMode, ThemeMode.system);
      expect(notified, isTrue);
    });

    test('setThemeMode → persistei στη βάση και reactive update', () async {
      await provider.initialize();
      await provider.setThemeMode(ThemeMode.dark);

      // Διαβάζεται από τη βάση (persistence)
      final persisted = await dao.getThemeMode();
      expect(persisted, ThemeMode.dark);
    });

    test('reactive: stream από SettingDao περνάει στον provider', () async {
      await provider.initialize();

      // Εξωτερική αλλαγή στη βάση (όχι μέσω provider) → live update.
      final future = provider.themeStream.first;
      await dao.setThemeMode(ThemeMode.light);
      expect(await future, ThemeMode.light);
    });

    test('toggleTheme light → dark (μέσω βάσης)', () async {
      await provider.initialize();
      await provider.setThemeMode(ThemeMode.light);

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);
    });

    test('dispose δεν πετάει', () async {
      await provider.initialize();
      expect(() => provider.dispose(), returnsNormally);
    });
  });
}