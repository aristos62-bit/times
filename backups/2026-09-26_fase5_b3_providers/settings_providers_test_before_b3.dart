/// Unit tests — settings_providers.dart (Φάση 4, Βήμα 1 · DESIGN §2.3).
///
/// `ProviderContainer.test()` (Riverpod 3.x) + override των SharedPreferences
/// (πρότυπο database_providers_test). Το read είναι σύγχρονο (review fix
/// 23-09) — το persisted mode είναι ορατό στο πρώτο read· το
/// `pumpEventQueue()` χρειάζεται μόνο για το async save.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/repositories/settings_repository.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

  group('themeModeProvider', () {
    // ─── Χαρούμενη ροή ───────────────────────────────────────────────────────
    test('αρχική κατάσταση = persisted αμέσως (sync read, zero flash)',
        () async {
      await prefs.setString(AppConstants.themeModeKey, 'dark');
      // Χωρίς pumpEventQueue — το πρώτο read βλέπει ήδη το persisted.
      expect(container().read(themeModeProvider), ThemeMode.dark);
    });

    test('χωρίς τιμή → default αμέσως', () {
      expect(container().read(themeModeProvider), AppTheme.defaultMode);
    });

    test('persisted mode ορατό χωρίς αναμονή (SEED dark)', () async {
      await prefs.setString(AppConstants.themeModeKey, 'dark');
      expect(container().read(themeModeProvider), ThemeMode.dark);
    });

    test('setMode αλλάζει state και το persists στο prefs', () async {
      final c = container();
      c.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(c.read(themeModeProvider), ThemeMode.light);
      await pumpEventQueue();
      expect(prefs.getString(AppConstants.themeModeKey), 'light');
    });

    test('setMode με το ήδη επιλεγμένο mode → no-op (equality gate, χωρίς '
        'overwrite)', () async {
      await prefs.setString(AppConstants.themeModeKey, 'dark');
      final c = container(); // state = dark αμέσως (sync read)
      c.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(c.read(themeModeProvider), ThemeMode.dark);
      expect(prefs.getString(AppConstants.themeModeKey), 'dark');
    });

    test('singleton: ίδιες αναγνώσεις επιστρέφουν το ίδιο instance (NON-'
        'autoDispose)', () {
      final c = container();
      expect(
        c.read(themeModeProvider.notifier),
        same(c.read(themeModeProvider.notifier)),
      );
    });

    // ─── Error paths & races ─────────────────────────────────────────────────
    test('save αποτυχία → state μένει στη μνήμη (χωρίς crash)', () async {
      final c = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(FailingRepository()),
        ],
      );
      c.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      expect(c.read(themeModeProvider), ThemeMode.dark);
      await pumpEventQueue();
      // Η αποτυχία του save ΔΕΝ αναιρεί την (ορατή) επιλογή στη συνεδρία.
      expect(c.read(themeModeProvider), ThemeMode.dark);
    });

    test('read αποτυχία → default αμέσως + ο χρήστης διαλέγει κανονικά', () {
      final c = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(FailingRepository()),
        ],
      );
      // Το sync throw πιάνεται στο build() → default, κανένα crash.
      expect(c.read(themeModeProvider), AppTheme.defaultMode);
      c.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(c.read(themeModeProvider), ThemeMode.light);
    });

    test('sync read: καμία async «τρύπα» — setMode αμέσως μετά το read',
        () async {
      await prefs.setString(AppConstants.themeModeKey, 'dark');
      final c = container();
      expect(c.read(themeModeProvider), ThemeMode.dark);
      c.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(c.read(themeModeProvider), ThemeMode.light);
      await pumpEventQueue();
      expect(prefs.getString(AppConstants.themeModeKey), 'light');
    });
  });

  group('DI δέντρο — τύποι', () {
    test('settingsRepositoryProvider είναι SettingsRepositoryImpl (singleton)',
        () {
      final c = container();
      final repo = c.read(settingsRepositoryProvider);
      expect(repo, isA<SettingsRepository>());
      expect(c.read(settingsRepositoryProvider), same(repo));
    });
  });
}

/// Fake repository — κάθε λειτουργία ρίχνει (read & save fail).
class FailingRepository implements SettingsRepository {
  @override
  ThemeMode readThemeMode() => throw UnimplementedError('read fail');

  @override
  Future<void> saveThemeMode(ThemeMode mode) =>
      throw UnimplementedError('save fail');
}
