/// Unit tests — `SelectedTrendItem` (§2.1 · 28-09-2026, Q5).
///
/// Plain Notifier (pattern theme): sync read, equality gate, async persist
/// `trendSelectedItemKey` (missing → null). In-memory SharedPreferences
/// (pattern `settings_repository_impl_test`).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:times/core/constants/app_constants.dart';
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

  group('SelectedTrendItem (§2.1 · 28-09-2026)', () {
    test('χωρίς τιμή → null (idle)', () {
      expect(container().read(selectedTrendItemProvider), isNull);
    });

    test('select → state + persist', () async {
      final c = container();
      c.read(selectedTrendItemProvider.notifier).select(7);
      expect(c.read(selectedTrendItemProvider), 7);
      // Persist: νέο container διαβάζει την ίδια τιμή.
      await waitForPrefs(
        () => prefs.getInt(AppConstants.trendSelectedItemKey) == 7,
      );
      expect(container().read(selectedTrendItemProvider), 7);
    });

    test('ίδιο id → no-op (equality gate)', () async {
      final c = container();
      c.read(selectedTrendItemProvider.notifier).select(7);
      c.read(selectedTrendItemProvider.notifier).select(7);
      expect(c.read(selectedTrendItemProvider), 7);
    });

    test('clear → null + αφαίρεση key', () async {
      final c = container();
      c.read(selectedTrendItemProvider.notifier).select(7);
      c.read(selectedTrendItemProvider.notifier).clear();
      expect(c.read(selectedTrendItemProvider), isNull);
      await waitForPrefs(
        () => prefs.getInt(AppConstants.trendSelectedItemKey) == null,
      );
    });

    test('clear σε null → no-op', () {
      final c = container();
      c.read(selectedTrendItemProvider.notifier).clear();
      expect(c.read(selectedTrendItemProvider), isNull);
    });
  });
}
