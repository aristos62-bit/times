/// SPoT: Καθαροί helpers γραφημάτων Κεντρικής (§2.1 · Φάση 5 Βήμα 3).
///
/// `resolvePeriodRange`: περίοδος → όρια `[from, to)` (start-inclusive /
/// end-exclusive, precedent `watchSummariesByDay`). `toChartSlices`:
/// ordered totals → φέτες top-N + συνθετικό «Λοιπά» (exact υπόλοιπο, Q1
/// Βήματος 2). Καθαροί και σύγχρονοι: δεν διαβάζουν UI/DB/theme, δεν κάνουν
/// logging (pattern `ReceiptValidator`/`NameValidator` — logging στον καλούντα).
/// Το `now` περνά ως όρισμα (hermetic tests, χωρίς `DateTime.now` μέσα).
library;

import '../../core/constants/app_enums.dart';
import '../../core/utils/dates.dart' as dates;
import '../../data/models/chart_totals.dart';

/// Επιλύει τα όρια `[from, to)` μιας περιόδου (§2.1 · Φάση 5 Βήμα 3):
/// day = ημέρα `now` · week = Δευτέρα–Κυριακή της `now` · month/year =
/// τρέχων μήνας/έτος · custom = οι μέρες [customFrom, customTo] ολόκληρες
/// (to = επομένη του `customTo`). Null custom ή `from > to` → άδειο
/// (`from == to`, ο καλών δείχνει `noPricesForPeriod`, §2.1:185).
/// Ημερολογιακή αριθμητική SPoT (`dates.addDays`, 01-10-2026) — το
/// `Duration` σε τοπικά μεσάνυχτα σπάει στις αλλαγές ώρας (23ωρες/25ωρες).
({DateTime from, DateTime to}) resolvePeriodRange(
  PeriodType period, {
  DateTime? customFrom,
  DateTime? customTo,
  required DateTime now,
}) {
  switch (period) {
    case PeriodType.day:
      final start = dates.dayOnly(now);
      return (from: start, to: dates.addDays(start, 1));
    case PeriodType.week:
      final today = dates.dayOnly(now);
      final start = dates.addDays(today, -(today.weekday - 1));
      return (from: start, to: dates.addDays(start, 7));
    case PeriodType.month:
      final start = DateTime(now.year, now.month);
      final end = now.month == DateTime.december
          ? DateTime(now.year + 1)
          : DateTime(now.year, now.month + 1);
      return (from: start, to: end);
    case PeriodType.year:
      return (from: DateTime(now.year), to: DateTime(now.year + 1));
    case PeriodType.custom:
      if (customFrom == null || customTo == null) {
        final empty = dates.dayOnly(now);
        return (from: empty, to: empty);
      }
      final from = dates.dayOnly(customFrom);
      final to = dates.addDays(dates.dayOnly(customTo), 1);
      if (!from.isBefore(to)) {
        final empty = dates.dayOnly(now);
        return (from: empty, to: empty);
      }
      return (from: from, to: to);
  }
}

/// Μετατρέπει ordered totals σε φέτες πίτας: οι πρώτες [limit] + συνθετικό
/// «Λοιπά» με το ακριβές υπόλοιπο (Q1 Βήματος 2 — η SQL δεν κάνει LIMIT).
/// Κενή λίστα ή `limit <= 0` → `[]` · λιγότερες από [limit] → όλες (χωρίς
/// «Λοιπά»). `othersLabel` από τον καλούντα (SPoT `AppStrings`, §1.1).
List<ChartSlice> toChartSlices<T>(
  List<T> rows, {
  required String Function(T row) labelOf,
  required int Function(T row) totalOf,
  required int limit,
  required String othersLabel,
}) {
  if (rows.isEmpty || limit <= 0) return const [];
  if (rows.length <= limit) {
    return [
      for (final row in rows)
        (label: labelOf(row), totalCents: totalOf(row)),
    ];
  }
  var rest = 0;
  for (final row in rows.skip(limit)) {
    rest += totalOf(row);
  }
  return [
    for (final row in rows.take(limit))
      (label: labelOf(row), totalCents: totalOf(row)),
    (label: othersLabel, totalCents: rest),
  ];
}

/// Μετατρέπει ordered ποσότητες σε φέτες: οι πρώτες [limit] + συνθετικό
/// «Λοιπά» με το ακριβές υπόλοιπο (mirror `toChartSlices` για doubles —
/// ξεχωριστή συνάρτηση 29-09-2026 αντί γενίκευσης: το `ChartSlice.totalCents`
/// είναι `int`-bound και η γενίκευση θα έσπαγε typedef + πίτα + fallback).
List<ChartQtySlice> toQtySlices<T>(
  List<T> rows, {
  required String Function(T row) labelOf,
  required double Function(T row) qtyOf,
  required int limit,
  required String othersLabel,
}) {
  if (rows.isEmpty || limit <= 0) return const [];
  if (rows.length <= limit) {
    return [
      for (final row in rows) (label: labelOf(row), qty: qtyOf(row)),
    ];
  }
  var rest = 0.0;
  for (final row in rows.skip(limit)) {
    rest += qtyOf(row);
  }
  return [
    for (final row in rows.take(limit))
      (label: labelOf(row), qty: qtyOf(row)),
    (label: othersLabel, qty: rest),
  ];
}
