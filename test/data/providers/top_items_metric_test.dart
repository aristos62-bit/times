/// Unit tests — `TopItemsMetricController` (§2.1 · 29-09-2026).
///
/// Plain Notifier (pattern theme/trend): default euros, equality gate,
/// async persist `topItemsMetricKey`. In-memory SharedPreferences.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
import 'package:times/data/models/chart_totals.dart';
import 'package:times/data/providers/settings_providers.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

  /// Περιμένει το unawaited persist (bounded poll — όχι flaky sleep).
  Future<void> waitForPrefs(bool Function() done) async {
    for (var i = 0; i < 100 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(done(), isTrue, reason: 'Το persist δεν ολοκληρώθηκε');
  }

  group('TopItemsMetricController (§2.1 · 29-09-2026)', () {
    test('χωρίς τιμή → euros (default Q3)', () {
      expect(container().read(topItemsMetricProvider), TopItemsMetric.euros);
    });

    test('setMetric → state + persist', () async {
      final c = container();
      c.read(topItemsMetricProvider.notifier).setMetric(TopItemsMetric.kilos);
      expect(c.read(topItemsMetricProvider), TopItemsMetric.kilos);
      await waitForPrefs(
        () => prefs.getString(AppConstants.topItemsMetricKey) == 'kilos',
      );
      expect(container().read(topItemsMetricProvider), TopItemsMetric.kilos);
    });

    test('ίδια τιμή → no-op (equality gate)', () {
      final c = container();
      c.read(topItemsMetricProvider.notifier).setMetric(TopItemsMetric.euros);
      expect(c.read(topItemsMetricProvider), TopItemsMetric.euros);
    });

    test('labels/abbreviations SPoT (§1.1)', () {
      expect(topItemsMetricLabel(TopItemsMetric.euros), '€');
      expect(topItemsMetricLabel(TopItemsMetric.pieces), 'Τεμ');
      expect(topItemsMetricLabel(TopItemsMetric.kilos), 'Κιλ');
      expect(topItemsMetricLabel(TopItemsMetric.liters), 'Λιτ');
      expect(topItemsMetricAbbreviation(TopItemsMetric.euros), isNull);
      expect(topItemsMetricAbbreviation(TopItemsMetric.pieces), 'τεμ');
      expect(topItemsMetricAbbreviation(TopItemsMetric.kilos), 'κιλ');
      expect(topItemsMetricAbbreviation(TopItemsMetric.liters), 'λτ');
    });
  });
}
