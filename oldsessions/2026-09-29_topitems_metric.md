# Κεφάλαιο 64 — Top-10 με μετρική €/Τεμ/Κιλ/Λτ (29-09-2026)

> Dropdown μετρικής στην κάρτα Top-10 (δίπλα στο period): € (αμετάβλητο) ·
> Τεμ/Κιλ/Λτ (top-10 ποσοτήτων, μία μονάδα ανά query — ποτέ ανάμειξη).
> Αποφάσεις Q1–Q6 (όλες οι προτάσεις).

## Data/UI (λεπτό layer)

- `TopItemsMetric` + 5 SPoT labels · `ItemQtyTotal`/`ChartQtySlice`/
  `TopItemsQtyQuery` · `ReceiptDao.watchTopItemsByUnit` (SUM/GROUP, SQL
  `ROUND(...,3)`, ORDER qty+name, readsFrom 3) · repo passthrough (6 fakes) ·
  `topItemsByUnitProvider` (top-10+«Λοιπά» via `toQtySlices`) · unit lookup
  in-memory από abbreviation (miss → empty, gated — smoke συμβατό).
- `toQtySlices` mirror (το int-bound `toChartSlices` ΔΕΝ γενικεύτηκε —
  θα έσπαγε typedef+πίτα+fallback).
- `QtyPieChart` (reuse `Pie3dPainter` + palette · legend ποσοτήτων + σύνολο
  Q6 · fallback) · `TopItemsCard` (period + metric selectors, €/qty bodies) ·
  shared `chart_state_views.dart` (εξαγωγή από home card, αμετάβλητη
  συμπεριφορά) · `topItemsMetricProvider` (persisted key, όχι migration) ·
  Προσαρμογή υπότιτλος «Μήνας · €».

## Ευρήματα

- Ε1 double σε λάθος DAO (η μέθοδος ζει στο ReceiptDao, όπως τα totals).
- Ε2 DropdownMenu: field EditableText + Text διπλά → predicate + `.first` ·
  4 βέλη (2/menu) → tap στο εμφανιζόμενο κείμενο.
- Ε3 home dark test 5→4 `HomeChartCard` + `TopItemsCard` present.
- Ε4 controller last-item test → `itemTrend` (όχι πια `topItems`).
- Ε5 2 fakes `SettingsRepository` (όχι 1) · `const` record με DateTime.
- Ε6 `find.byType(CustomPaint)` αναξιόπιστο (Material) → type asserts.

## Tests (+39 → 1429/1429)

- Νέα: DAO 3 · repo 3 · provider 4 · helpers 4 · metric persist 4 ·
  qty chart 6 · card 8 · settings repo 4 · SPoT +5 · customization +1.
- Ενημερωμένα: home_page (dark) · customization (subtitle) · controller
  (last) · 6 fakes · SPoT registries · card refactor (υπάρχοντα περνούν).
- Full suite **1429/1429** ✓ · `flutter analyze` No issues ✓.
- DESIGN §2.1 (μετρικές) · backup `backups/2026-09-29_topitems_metric/`.
