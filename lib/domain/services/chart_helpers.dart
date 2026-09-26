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
import '../../data/models/chart_totals.dart';

/// Κανονικοποιεί σε μέρα (χωρίς ώρα) — τοπικό helper (όχι `DateUtils`: το
/// domain δεν εξαρτάται από το UI · pattern `watchSummariesByDay` §3).
DateTime _dayOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Επιλύει τα όρια `[from, to)` μιας περιόδου (§2.1 · Φάση 5 Βήμα 3):
/// day = ημέρα `now` · week = Δευτέρα–Κυριακή της `now` · month/year =
/// τρέχων μήνας/έτος · custom = οι μέρες [customFrom, customTo] ολόκληρες
/// (to = επομένη του `customTo`). Null custom ή `from > to` → άδειο
/// (`from == to`, ο καλών δείχνει `noPricesForPeriod`, §2.1:185).
/// Calendar bounds (όχι `Duration` σε μήνα/έτος — DST-ασφαλές).
({DateTime from, DateTime to}) resolvePeriodRange(
  PeriodType period, {
  DateTime? customFrom,
  DateTime? customTo,
  required DateTime now,
}) {
  switch (period) {
    case PeriodType.day:
      final start = _dayOnly(now);
      return (from: start, to: start.add(const Duration(days: 1)));
    case PeriodType.week:
      final today = _dayOnly(now);
      final start = today.subtract(Duration(days: today.weekday - 1));
      return (from: start, to: start.add(const Duration(days: 7)));
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
        final empty = _dayOnly(now);
        return (from: empty, to: empty);
      }
      final from = _dayOnly(customFrom);
      final to = _dayOnly(customTo).add(const Duration(days: 1));
      if (!from.isBefore(to)) {
        final empty = _dayOnly(now);
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
