/// Unit tests για το SPoT `todayProvider` (§2.1 · 27-09-2026).
///
/// Σύγχρονα, χωρίς DB/FakeAsync: η λογική ημέρας ελέγχεται μέσω του
/// test-hook `checkNow` (hermetic, pattern `resolvePeriodRange(now:)`) —
/// το `Timer.periodic` είναι trivial wiring (tick → `checkNow(now)`) και
/// ακυρώνεται στο dispose (`ref.onDispose`). Real 60s timer: δεν πυροδοτεί
/// ποτέ μέσα στα γρήγορα tests, το dispose τον ακυρώνει (κανένα hang).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/providers/stream_providers.dart';

void main() {
  group('TodayController.dayOnly', () {
    test('κόβει ώρα/λεπτά/δευτερόλεπτα', () {
      expect(
        TodayController.dayOnly(DateTime(2026, 9, 27, 23, 59, 59)),
        DateTime(2026, 9, 27),
      );
    });

    test('μεσάνυχτα μένουν ίδια', () {
      expect(
        TodayController.dayOnly(DateTime(2026, 9, 27)),
        DateTime(2026, 9, 27),
      );
    });
  });

  group('todayProvider', () {
    test('αρχικό state = σημερινή ημέρα (dayOnly)', () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);
      final now = DateTime.now();
      expect(
        container.read(todayProvider),
        DateTime(now.year, now.month, now.day),
      );
    });

    test('checkNow ίδια ημέρα (άλλη ώρα) → καμία ειδοποίηση', () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);
      var emissions = 0;
      container.listen<DateTime>(todayProvider, (prev, next) => emissions++);
      container
          .read(todayProvider.notifier)
          .checkNow(DateTime.now().add(const Duration(hours: 2)));
      expect(emissions, 0);
    });

    test('checkNow επόμενη ημέρα → νέο state + ειδοποίηση', () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);
      var emissions = 0;
      DateTime? seen;
      container.listen<DateTime>(
        todayProvider,
        (prev, next) {
          emissions++;
          seen = next;
        },
      );
      final before = container.read(todayProvider);
      final tomorrow = before.add(const Duration(days: 1, hours: 2));
      container.read(todayProvider.notifier).checkNow(tomorrow);
      expect(emissions, 1);
      expect(seen, DateTime(tomorrow.year, tomorrow.month, tomorrow.day));
      expect(container.read(todayProvider), seen);
    });

    test('checkNow παλιότερη ημέρα → ενημερώνει (χειροκίνητη αλλαγή ρολογιού)', () {
      final container = ProviderContainer.test();
      addTearDown(container.dispose);
      final before = container.read(todayProvider);
      final yesterday = before.subtract(const Duration(days: 1));
      container.read(todayProvider.notifier).checkNow(yesterday);
      expect(container.read(todayProvider), yesterday);
    });
  });
}
