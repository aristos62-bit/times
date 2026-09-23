/// Unit tests — `SettingsRepositoryImpl` (Φάση 4, Βήμα 1 · DESIGN §2.3).
///
/// In-memory SharedPreferences μέσω `setMockInitialValues` (χωρίς widget —
/// το store είναι pure Dart, δεν χρειάζεται binding). Defaults από τον SPoT
/// `AppTheme.defaultMode` (§1.5) — όχι hardcoded 'system'.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/repositories/settings_repository.dart';
import 'package:times/data/repositories/settings_repository_impl.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  SettingsRepositoryImpl newRepo() => SettingsRepositoryImpl(prefs);

  group('SettingsRepositoryImpl', () {
    // ─── loadThemeMode ───────────────────────────────────────────────────────
    test('χωρίς τιμή → AppTheme.defaultMode (§2.3:270)', () async {
      expect(await newRepo().loadThemeMode(), AppTheme.defaultMode);
    });

    test('κενή τιμή → AppTheme.defaultMode', () async {
      await prefs.setString(AppConstants.themeModeKey, '');
      expect(await newRepo().loadThemeMode(), AppTheme.defaultMode);
    });

    test('άγνωστη τιμή (π.χ. από παλιά έκδοση) → AppTheme.defaultMode', () async {
      await prefs.setString(AppConstants.themeModeKey, 'sepia');
      expect(await newRepo().loadThemeMode(), AppTheme.defaultMode);
    });

    for (final mode in ThemeMode.values) {
      test('round-trip: `${mode.name}` αποθηκεύεται και διαβάζεται', () async {
        final repo = newRepo();
        await repo.saveThemeMode(mode);
        expect(await repo.loadThemeMode(), mode);
      });
    }

    // ─── saveThemeMode ───────────────────────────────────────────────────────
    test('save αντικαθιστά την προηγούμενη τιμή', () async {
      final repo = newRepo();
      await repo.saveThemeMode(ThemeMode.light);
      await repo.saveThemeMode(ThemeMode.dark);
      expect(await repo.loadThemeMode(), ThemeMode.dark);
    });

    test('γράφει στον SPoT key AppConstants.themeModeKey', () async {
      final repo = newRepo();
      await repo.saveThemeMode(ThemeMode.system);
      expect(prefs.getString(AppConstants.themeModeKey), 'system');
    });

    test('εμφανίζεται με το abstract interface SettingsRepository', () {
      expect(newRepo(), isA<SettingsRepository>());
    });
  });
}