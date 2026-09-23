/// Unit tests — settings_providers.dart (Φάση 4, Βήμα 1 · DESIGN §2.3).
///
/// `ProviderContainer.test()` (Riverpod 3.x) + override των SharedPreferences
/// (πρότυπο database_providers_test). Το async load ολοκληρώνεται με το
/// τυποποιημένο `pumpEventQueue()` (flutter_test) — κανένα sleep.
library;

import 'dart:async';

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
    test('αρχική κατάσταση = default πριν ολοκληρωθεί το load', () {
      expect(container().read(themeModeProvider), AppTheme.defaultMode);
    });

    test('μετά το load = persisted mode (SEED dark)', () async {
      await prefs.setString(AppConstants.themeModeKey, 'dark');
      final c = container();
      expect(c.read(themeModeProvider), AppTheme.defaultMode);
      await pumpEventQueue();
      expect(c.read(themeModeProvider), ThemeMode.dark);
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
      final c = container();
      await pumpEventQueue(); // load ολοκληρώνεται (state = dark)
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

    test('load αποτυχία → default + ο χρήστης μπορεί κανονικά να διαλέξει',
        () async {
      final c = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(FailingRepository()),
        ],
      );
      await pumpEventQueue();
      expect(c.read(themeModeProvider), AppTheme.defaultMode);
      c.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(c.read(themeModeProvider), ThemeMode.light);
    });

    test('race: ο χρήστης επιλέγει ΠΡΙΝ τελειώσει το load → η επιλογή κερδίζει',
        () async {
      final slow = SlowRepository();
      final c = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(slow),
        ],
      );
      expect(c.read(themeModeProvider), AppTheme.defaultMode);
      c.read(themeModeProvider.notifier).setMode(ThemeMode.light);
      expect(c.read(themeModeProvider), ThemeMode.light);
      slow.completeLoad(ThemeMode.dark); // το (αργοπορημένο) persisted = dark
      await pumpEventQueue();
      // Το _userChanged guard κρατά την επιλογή του χρήστη.
      expect(c.read(themeModeProvider), ThemeMode.light);
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

/// Fake repository — κάθε λειτουργία ρίχνει (load & save fail).
class FailingRepository implements SettingsRepository {
  @override
  Future<ThemeMode> loadThemeMode() => throw UnimplementedError('load fail');

  @override
  Future<void> saveThemeMode(ThemeMode mode) =>
      throw UnimplementedError('save fail');
}

/// Fake repository — το load κρατιέται ανεκπλήρωτο μέχρι να το «αφήσουμε»
/// (προσομοίωση αργού persisted load + race με την επιλογή του χρήστη).
class SlowRepository implements SettingsRepository {
  final Completer<ThemeMode> _load = Completer<ThemeMode>();

  void completeLoad(ThemeMode mode) => _load.complete(mode);

  @override
  Future<ThemeMode> loadThemeMode() => _load.future;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {}
}