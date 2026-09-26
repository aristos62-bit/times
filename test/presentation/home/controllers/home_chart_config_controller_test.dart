/// Unit tests — `HomeChartConfigController` (§2.1 · Φάση 5 Βήμα 3).
///
/// `ProviderContainer.test()` + mock prefs (pattern `settings_providers_test`):
/// sync read αμέσως · async save με `pumpEventQueue()` · equality no-op ·
/// failing repo (state μένει, χωρίς crash).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_enums.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/data/repositories/settings_repository.dart';
import 'package:times/presentation/home/controllers/home_chart_config_controller.dart';
import 'package:times/presentation/home/state/home_chart_config.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

  group('homeChartConfigProvider', () {
    test('αρχική κατάσταση = defaults αμέσως (§2.1)', () {
      expect(container().read(homeChartConfigProvider), HomeChartConfig.defaults());
    });

    test('setVisible αλλάζει + persists', () async {
      final c = container();
      c.read(homeChartConfigProvider.notifier).setVisible(ChartId.supplier, false);
      expect(c.read(homeChartConfigProvider).supplier.visible, isFalse);
      await pumpEventQueue();
      // Επαναφόρτωση από τα ίδια prefs βλέπει το persisted.
      final c2 = ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      expect(c2.read(homeChartConfigProvider).supplier.visible, isFalse);
    });

    test('setVisible ίδια τιμή → no-op (equality gate)', () {
      final c = container();
      final before = c.read(homeChartConfigProvider);
      c.read(homeChartConfigProvider.notifier).setVisible(ChartId.supplier, true);
      expect(c.read(homeChartConfigProvider), before);
    });

    test('setPeriod αλλάζει + καθαρίζει custom όταν φεύγει από custom', () {
      final c = container();
      final notifier = c.read(homeChartConfigProvider.notifier);
      notifier.setPeriod(
        ChartId.category,
        PeriodType.custom,
        customFrom: DateTime(2026, 1, 1),
        customTo: DateTime(2026, 1, 31),
      );
      expect(c.read(homeChartConfigProvider).category.period, PeriodType.custom);
      notifier.setPeriod(ChartId.category, PeriodType.year);
      final entry = c.read(homeChartConfigProvider).category;
      expect(entry.period, PeriodType.year);
      expect(entry.customFrom, isNull);
      expect(entry.customTo, isNull);
    });

    test('setPeriod custom χωρίς range → no-op (defensive)', () {
      final c = container();
      final before = c.read(homeChartConfigProvider);
      c.read(homeChartConfigProvider.notifier).setPeriod(ChartId.category, PeriodType.custom);
      expect(c.read(homeChartConfigProvider), before);
    });

    test('moveDown/moveUp ανταλλάσσουν orders', () {
      final c = container();
      final notifier = c.read(homeChartConfigProvider.notifier);
      notifier.moveDown(ChartId.supplier);
      var state = c.read(homeChartConfigProvider);
      expect(state.supplier.order, 1);
      expect(state.category.order, 0);
      notifier.moveUp(ChartId.supplier);
      state = c.read(homeChartConfigProvider);
      expect(state.supplier.order, 0);
      expect(state.category.order, 1);
    });

    test('moveUp στην κορυφή / moveDown στο τέλος → no-op', () {
      final c = container();
      final notifier = c.read(homeChartConfigProvider.notifier);
      final before = c.read(homeChartConfigProvider);
      notifier.moveUp(ChartId.supplier);
      notifier.moveDown(ChartId.topItems);
      expect(c.read(homeChartConfigProvider), before);
    });

    test('resetDefaults επαναφέρει + no-op όταν ήδη defaults', () {
      final c = container();
      final notifier = c.read(homeChartConfigProvider.notifier);
      notifier.setVisible(ChartId.supplier, false);
      notifier.resetDefaults();
      expect(c.read(homeChartConfigProvider), HomeChartConfig.defaults());
      final before = c.read(homeChartConfigProvider);
      notifier.resetDefaults();
      expect(c.read(homeChartConfigProvider), before);
    });

    test('singleton (NON-autoDispose)', () {
      final c = container();
      expect(
        c.read(homeChartConfigProvider.notifier),
        same(c.read(homeChartConfigProvider.notifier)),
      );
    });

    test('save αποτυχία → state μένει (χωρίς crash)', () async {
      final c = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(_FailingChartRepository()),
        ],
      );
      c.read(homeChartConfigProvider.notifier).setVisible(ChartId.supplier, false);
      expect(c.read(homeChartConfigProvider).supplier.visible, isFalse);
      await pumpEventQueue();
      expect(c.read(homeChartConfigProvider).supplier.visible, isFalse);
    });

    test('read αποτυχία → defaults + ο χρήστης αλλάζει κανονικά', () {
      final c = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(_FailingChartRepository()),
        ],
      );
      expect(c.read(homeChartConfigProvider), HomeChartConfig.defaults());
      c.read(homeChartConfigProvider.notifier).setVisible(ChartId.supplier, false);
      expect(c.read(homeChartConfigProvider).supplier.visible, isFalse);
    });
  });
}

/// Fake settings repository — ρίχνει σε chart config (read & save fail,
/// pattern `FailingRepository` του `settings_providers_test`).
class _FailingChartRepository implements SettingsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('chart config fail');
}
