/// Unit tests — `SettingsRepositoryImpl` (Φάση 4, Βήμα 1 · DESIGN §2.3).
///
/// In-memory SharedPreferences μέσω `setMockInitialValues` (χωρίς widget —
/// το store είναι pure Dart, δεν χρειάζεται binding). Defaults από τον SPoT
/// `AppTheme.defaultMode` (§1.5) — όχι hardcoded 'system'.
///
/// Refactor 4 επιπέδων (27-09-2026): το 3ο γράφημα είναι Τμήμα — JSON key
/// `itemGroup` (με legacy fallback `subCategory` → itemGroup, τα prefs
/// επιβιώνουν του DB wipe).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/core/constants/app_enums.dart';
import 'package:times/core/theme/app_theme.dart';
import 'package:times/data/repositories/settings_repository.dart';
import 'package:times/data/repositories/settings_repository_impl.dart';
import 'package:times/presentation/home/state/home_chart_config.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  SettingsRepositoryImpl newRepo() => SettingsRepositoryImpl(prefs);

  group('SettingsRepositoryImpl', () {
    // ─── readThemeMode (sync) ────────────────────────────────────────────────
    test('χωρίς τιμή → AppTheme.defaultMode (§2.3:270)', () {
      expect(newRepo().readThemeMode(), AppTheme.defaultMode);
    });

    test('κενή τιμή → AppTheme.defaultMode', () async {
      await prefs.setString(AppConstants.themeModeKey, '');
      expect(newRepo().readThemeMode(), AppTheme.defaultMode);
    });

    test('άγνωστη τιμή (π.χ. από παλιά έκδοση) → AppTheme.defaultMode', () async {
      await prefs.setString(AppConstants.themeModeKey, 'sepia');
      expect(newRepo().readThemeMode(), AppTheme.defaultMode);
    });

    for (final mode in ThemeMode.values) {
      test('round-trip: `${mode.name}` αποθηκεύεται και διαβάζεται', () async {
        final repo = newRepo();
        await repo.saveThemeMode(mode);
        expect(repo.readThemeMode(), mode);
      });
    }

    // ─── saveThemeMode ───────────────────────────────────────────────────────
    test('save αντικαθιστά την προηγούμενη τιμή', () async {
      final repo = newRepo();
      await repo.saveThemeMode(ThemeMode.light);
      await repo.saveThemeMode(ThemeMode.dark);
      expect(repo.readThemeMode(), ThemeMode.dark);
    });

    test('γράφει στον SPoT key AppConstants.themeModeKey', () async {
      final repo = newRepo();
      await repo.saveThemeMode(ThemeMode.system);
      expect(prefs.getString(AppConstants.themeModeKey), 'system');
    });

    test('εμφανίζεται με το abstract interface SettingsRepository', () {
      expect(newRepo(), isA<SettingsRepository>());
    });

    // ─── readHomeChartConfig (sync · Φάση 5 Βήμα 3) ──────────────────────────
    test('χωρίς τιμή → HomeChartConfig.defaults() (§2.1)', () {
      expect(newRepo().readHomeChartConfig(), HomeChartConfig.defaults());
    });

    test('μη-JSON τιμή → defaults (χωρίς throw)', () async {
      await prefs.setString(AppConstants.homeChartConfigKey, 'not-json{{{');
      expect(newRepo().readHomeChartConfig(), HomeChartConfig.defaults());
    });

    test('corrupt entry → default entry (οι υγιείς κρατιούνται)', () async {
      await prefs.setString(
        AppConstants.homeChartConfigKey,
        jsonEncode({
          'supplier': {'visible': false, 'order': 0, 'period': 'year'},
          'category': 'corrupt',
          'itemGroup': {'visible': 'ναι', 'order': 'δύο'},
          'topItems': null,
        }),
      );
      final config = newRepo().readHomeChartConfig();
      expect(
        config.supplier,
        const ChartEntry(visible: false, order: 0, period: PeriodType.year),
      );
      expect(config.category, const ChartEntry(order: 1));
      expect(config.subCategory, const ChartEntry(order: 2));
      expect(config.itemGroup, const ChartEntry(order: 3));
      expect(config.topItems, const ChartEntry(order: 4));
    });

    test('παλιό 4-key JSON (χωρίς subCategory) → migration: θέση 2 + shift',
        () async {
      await prefs.setString(
        AppConstants.homeChartConfigKey,
        jsonEncode({
          'supplier': {'visible': true, 'order': 0, 'period': 'month'},
          'category': {'visible': false, 'order': 1, 'period': 'year'},
          'itemGroup': {'visible': true, 'order': 2, 'period': 'month'},
          'topItems': {'visible': true, 'order': 3, 'period': 'month'},
        }),
      );
      final config = newRepo().readHomeChartConfig();
      expect(config.supplier.order, 0);
      expect(config.category.order, 1);
      expect(
        config.subCategory,
        const ChartEntry(order: 2),
      );
      expect(config.itemGroup.order, 3);
      expect(config.topItems.order, 4);
      expect(config.category.visible, isFalse);
    });

    /// Νέο key `subCategory` (5η πίτα 27-09-2026): το παλιό `subCategory`
    /// (προ-4-επιπέδων) σήμαινε την παλιά πίτα — το legacy fallback
    /// καταργήθηκε, το key έχει πάλι την αρχική σημασία.
    test('key `subCategory` → διαβάζεται ως subCategory entry', () async {
      await prefs.setString(
        AppConstants.homeChartConfigKey,
        jsonEncode({
          'supplier': {'visible': true, 'order': 0, 'period': 'month'},
          'category': {'visible': true, 'order': 1, 'period': 'month'},
          'subCategory': {'visible': false, 'order': 2, 'period': 'year'},
          'itemGroup': {'visible': true, 'order': 3, 'period': 'month'},
          'topItems': {'visible': true, 'order': 4, 'period': 'month'},
        }),
      );
      final config = newRepo().readHomeChartConfig();
      expect(
        config.subCategory,
        const ChartEntry(visible: false, order: 2, period: PeriodType.year),
      );
      expect(config.itemGroup.order, 3);
    });

    test('άγνωστο period → month (SPoT default §2.1)', () async {
      await prefs.setString(
        AppConstants.homeChartConfigKey,
        jsonEncode({
          'supplier': {'visible': true, 'order': 0, 'period': 'trimester'},
        }),
      );
      expect(
        newRepo().readHomeChartConfig().supplier.period,
        PeriodType.month,
      );
    });

    test('round-trip: config με custom range', () async {
      final repo = newRepo();
      final config = HomeChartConfig(
        supplier: ChartEntry(
          visible: false,
          order: 2,
          period: PeriodType.custom,
          customFrom: DateTime(2026, 1, 1),
          customTo: DateTime(2026, 1, 31),
        ),
        category: const ChartEntry(order: 0),
        subCategory: const ChartEntry(order: 4),
        itemGroup: const ChartEntry(order: 1, period: PeriodType.year),
        topItems: const ChartEntry(order: 3, visible: false),
      );
      await repo.saveHomeChartConfig(config);
      expect(repo.readHomeChartConfig(), config);
    });

    test('γράφει στον SPoT key με 5 keys (με `subCategory`)', () async {
      await newRepo().saveHomeChartConfig(HomeChartConfig.defaults());
      final stored = prefs.getString(AppConstants.homeChartConfigKey);
      expect(stored, isNotNull);
      expect(stored, contains('supplier'));
      expect(stored, contains('subCategory'));
      expect(stored, contains('itemGroup'));
    });
  });
}
