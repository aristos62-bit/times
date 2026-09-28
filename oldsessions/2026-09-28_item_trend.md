# Κεφάλαιο 61 — 6ο γράφημα «Πορεία τιμής είδους» (28-09-2026)

> Deferred trend-line §2.1:175 → 6η κάρτα Αρχικής (γραμμή): επιλογή είδους
> (search, χωρίς «+») + περίοδος κάρτας + πορεία καθαρής €/μονάδας.
> Αποφάσεις Q1–Q6 (όλες α): καθαρή μονάδας · φίλτρο κλειδωμένης μονάδας +
> σημείωση · point/γραμμή · cap 200 · persist · 6η ορατή τελευταία.
> Προαπαιτούμενο: κλείδωμα μονάδας (κεφ. 60 — νέες μικτές αδύνατες).

## Data (λεπτό layer, §1.2)

- `chart_totals`: `ItemPricePoint` (+`unitId` για Q2, χωρίς join) ·
  `ItemTrendQuery{itemId,unitId,from,to}` · `ItemTrendData{points,otherUnitCount}`.
- `ReceiptLineDao.watchItemHistory` (customSelect INNER receipts+suppliers,
  net `price−discount` στο SQL, `date ASC,id ASC`, `readsFrom` 3 πίνακες).
- Repo passthrough + `DataLoadException` (6 fakes `implements
  ReceiptRepository` ενημερώθηκαν — pattern Βήματος 7).
- Providers: `itemTrendSearchProvider` (thin family, αντίγραφο supplier) +
  `itemTrendProvider` (autoDispose family: split μονάδας + cap νεότερα) +
  `selectedTrendItemProvider` (plain Notifier στο settings_providers —
  το settings repo δεν φαίνεται από stream_providers, αλλιώς κύκλος).

## UI (6η κάρτα + Προσαρμογή αυτόματα)

- `item_trend_chart.dart` (custom painter: grid/γραμμή/dots/TextPainter
  άξονες, Χ ομοιόμορφα ανά index, `boundsOf` @visibleForTesting, SPoT
  gutters/πάχη) · `item_trend_fallback_list.dart` (χωρίς σύνολο — άθροισμα
  μοναδιαίων = νόημα μηδέν, Α2) · `item_trend_card.dart` (selector reuse +
  banner + hasError-priority + skeleton · gated items-watch ΜΟΝΟ με επιλογή,
  §2.0.1 · epoch καθαρισμού).
- `home_page`: `titleOf` + branch (οι πίτες ατόφιες — `throw StateError`
  unreachable arm στο switch) · config Freezed 6 entries + regen build_runner
  (29s, μόνο το σωστό generated άλλαξε) · migration 5→6 χωρίς shift (θέση 5)
  · `trendSelectedItemKey` (int/remove).
- Προσαρμογή: 6η γραμμή αυτόματα (values-loop) — κανένα νέο widget.

## Ευρήματα (διορθωμένα στην πορεία)

- Ε1: `.future` δεν πιάνει drift εκπομπές (γνωστό search-tests) → listen+completer.
- Ε2: error-path + Riverpod retry → listen+completer (Βήμα 3), ποτέ `.future`.
- Ε3: `find.byType(TextField)` πιάνει και το DropdownMenu περιόδου → predicate με label.
- Ε4: `const` record με DateTime → `final` · λείπον import (settings_providers).
- Ε5: integer-only formatter κόβει το κόμμα (κεφ. 60) — λαμβάνεται υπόψιν.
- SPoT tests registries ενημερώθηκαν (strings/constants/messages + τιμές).

## Tests (+54 → 1313/1313)

- Νέα: DAO history 6 · repo history 3 · trend providers 7 (search×2, unit-Q2, empty, cap-200, error) · selection 5 · chart 9 (bounds×2 + 7 widget) · card 13 (states + search-flow + persist) · settings (migration 5→6 + 4 trend-id) · SPoT +6 · controller +1.
- Ενημερωμένα: home_page (6 τίτλοι/γραμμές) · customization (6) · controller (last=itemTrend) · 4-key/5-key migrations άθικτα.
- Full suite **1313/1313** ✓ · `flutter analyze` No issues ✓.
- DESIGN §2.1/§4 (6η κάρτα + deferred-activated) · backup
  `backups/2026-09-28_item_trend/` (21 αρχεία πριν το edit).
