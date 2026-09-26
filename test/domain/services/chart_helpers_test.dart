/// Unit tests για τους pure helpers `chart_helpers.dart`
/// (§2.1 · Φάση 5 Βήμα 3) — `resolvePeriodRange` + `toChartSlices`.
///
/// Καθαροί/σύγχρονοι → plain `test()`, χωρίς providers/DB (στυλ validators).
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_enums.dart';
import 'package:times/domain/services/chart_helpers.dart';

void main() {
  group('resolvePeriodRange', () {
    final now = DateTime(2026, 9, 16, 15, 30); // Τετάρτη

    test('day: ημέρα now (00:00 → +1)', () {
      final range = resolvePeriodRange(PeriodType.day, now: now);
      expect(range.from, DateTime(2026, 9, 16));
      expect(range.to, DateTime(2026, 9, 17));
    });

    test('week: Δευτέρα → +7 (now Τετάρτη)', () {
      final range = resolvePeriodRange(PeriodType.week, now: now);
      expect(range.from, DateTime(2026, 9, 14));
      expect(range.to, DateTime(2026, 9, 21));
    });

    test('week: Κυριακή ανήκει στην ίδια εβδομάδα (Δευτέρα)', () {
      final sunday = DateTime(2026, 9, 20, 23, 59);
      final range = resolvePeriodRange(PeriodType.week, now: sunday);
      expect(range.from, DateTime(2026, 9, 14));
      expect(range.to, DateTime(2026, 9, 21));
    });

    test('week: Δευτέρα → εαυτή (weekday edge)', () {
      final monday = DateTime(2026, 9, 14, 8);
      final range = resolvePeriodRange(PeriodType.week, now: monday);
      expect(range.from, DateTime(2026, 9, 14));
    });

    test('month: 1η → 1η επομένου', () {
      final range = resolvePeriodRange(PeriodType.month, now: now);
      expect(range.from, DateTime(2026, 9, 1));
      expect(range.to, DateTime(2026, 10, 1));
    });

    test('month: Δεκέμβριος → Ιανουάριος επόμενου έτους', () {
      final range = resolvePeriodRange(
        PeriodType.month,
        now: DateTime(2026, 12, 15),
      );
      expect(range.from, DateTime(2026, 12, 1));
      expect(range.to, DateTime(2027, 1, 1));
    });

    test('year: 1η Ιαν → 1η Ιαν επομένου', () {
      final range = resolvePeriodRange(PeriodType.year, now: now);
      expect(range.from, DateTime(2026, 1, 1));
      expect(range.to, DateTime(2027, 1, 1));
    });

    test('custom: ολόκληρες μέρες (to = επομένη customTo)', () {
      final range = resolvePeriodRange(
        PeriodType.custom,
        customFrom: DateTime(2026, 1, 10, 14),
        customTo: DateTime(2026, 1, 12, 9),
        now: now,
      );
      expect(range.from, DateTime(2026, 1, 10));
      expect(range.to, DateTime(2026, 1, 13));
    });

    test('custom ίδια μέρα → μία ημέρα', () {
      final range = resolvePeriodRange(
        PeriodType.custom,
        customFrom: DateTime(2026, 1, 10),
        customTo: DateTime(2026, 1, 10),
        now: now,
      );
      expect(range.from, DateTime(2026, 1, 10));
      expect(range.to, DateTime(2026, 1, 11));
    });

    test('custom null → άδειο (from == to, §2.1:185)', () {
      final range = resolvePeriodRange(PeriodType.custom, now: now);
      expect(range.from, range.to);
    });

    test('custom from > to → άδειο (defensive)', () {
      final range = resolvePeriodRange(
        PeriodType.custom,
        customFrom: DateTime(2026, 2, 1),
        customTo: DateTime(2026, 1, 1),
        now: now,
      );
      expect(range.from, range.to);
    });
  });

  group('toChartSlices', () {
    List<({String name, int total})> rows(List<int> totals) => [
          for (var i = 0; i < totals.length; i++)
            (name: 'N$i', total: totals[i]),
        ];

    test('κενή λίστα → [] · limit <= 0 → []', () {
      expect(
        toChartSlices(
          rows([]),
          labelOf: (r) => r.name,
          totalOf: (r) => r.total,
          limit: 8,
          othersLabel: 'Λοιπά',
        ),
        isEmpty,
      );
      expect(
        toChartSlices(
          rows([10]),
          labelOf: (r) => r.name,
          totalOf: (r) => r.total,
          limit: 0,
          othersLabel: 'Λοιπά',
        ),
        isEmpty,
      );
    });

    test('λιγότερες από limit → όλες, χωρίς «Λοιπά»', () {
      final slices = toChartSlices(
        rows([30, 20]),
        labelOf: (r) => r.name,
        totalOf: (r) => r.total,
        limit: 8,
        othersLabel: 'Λοιπά',
      );
      expect(slices.map((s) => s.totalCents), [30, 20]);
    });

    test('ακριβώς limit → όλες, χωρίς «Λοιπά»', () {
      final slices = toChartSlices(
        rows([30, 20]),
        labelOf: (r) => r.name,
        totalOf: (r) => r.total,
        limit: 2,
        othersLabel: 'Λοιπά',
      );
      expect(slices.length, 2);
      expect(slices.any((s) => s.label == 'Λοιπά'), isFalse);
    });

    test('περισσότερες → top-N + «Λοιπά» με ΑΚΡΙΒΕΣ υπόλοιπο', () {
      final slices = toChartSlices(
        rows([50, 40, 30, 20, 10]),
        labelOf: (r) => r.name,
        totalOf: (r) => r.total,
        limit: 2,
        othersLabel: 'Λοιπά',
      );
      expect(slices.map((s) => s.label), ['N0', 'N1', 'Λοιπά']);
      expect(slices.last.totalCents, 30 + 20 + 10);
    });

    test('άθροισμα φετών = άθροισμα γραμμών (τίποτα δεν χάνεται)', () {
      const totals = [50, 40, 30, 20, 10, 5, 1];
      final slices = toChartSlices(
        rows(totals),
        labelOf: (r) => r.name,
        totalOf: (r) => r.total,
        limit: 3,
        othersLabel: 'Λοιπά',
      );
      final sum = slices.fold<int>(0, (acc, s) => acc + s.totalCents);
      expect(sum, totals.reduce((a, b) => a + b));
    });
  });
}
