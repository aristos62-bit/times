# Κεφάλαιο 62 — Ενότητα «Στατιστικά» + καρτέλα είδους + export Excel/PDF (28-09-2026)

> 1η στατιστική ανάλυση (§2.3): νέα collapsible ενότητα Ρυθμίσεων (Θέμα →
> Στατιστικά → Είδη) — είδος (search) + περίοδος → πίνακας 7 στηλών +
> footer + export XLSX/PDF. Αποφάσεις Q1–Q7 (όλες οι προτάσεις).

## Deps + fonts (blockers Β1/Β2)

- `excel ^4.0.6` + `pdf ^3.12.0` (όχι 3.13: θέλει xml ^7 ≠ excel —
  evidence pub.dev API · pdf ≤3.12 → xml ^6 κοινό).
- `flutter_native_splash ^2.4.8→^2.4.4` (ήθελε archive ^4 ≠ excel —
  dev-only, η splash έχει παραχθεί).
- Fonts: Noto Sans Regular/Bold (OFL, ~543KB, magic `00 01 00 00` +
  ελληνικά) από jsdelivr expo-google-fonts (github raw: HTML/404) →
  `assets/fonts/` + assets entry (η Helvetica δεν έχει Greek glyphs).

## Data/UI (λεπτό layer)

- `ItemLedgerRow` (+`ItemLedgerQuery`) · `ReceiptLineDao.watchItemLedger`
  (joins receipts+suppliers+units, `date ASC,id ASC`, readsFrom 4) · repo
  passthrough (6 fakes ενημερώθηκαν) · `itemLedgerProvider` autoDispose
  family (cap `statsTableMaxRows`, ΟΛΕΣ οι μονάδες Q3).
- `StatisticsExportService` (pure): filename mirror · excel native αριθμοί
  (ημερομηνία `DateCellValue`, € doubles — αθροίσιμα, όχι locale) · PDF
  `MultiPage` A4 landscape + embedded TTF + σελίδες · `totalsOf` SPoT ·
  mirror formatters (τεκμηριωμένο — βέλος §2.5) · `StatsExportException`
  (πιάνει `Object`: οι pdf parsers πετούν `RangeError`, όχι Exception).
- `StatisticsController` (`_guarded`, cancel no-op, picker fail → throw) ·
  section (τοπικό state, Q5 · gated watches · epoch) · dumb
  `StatisticsTable` (scroll, numerics, footer, Semantics) · Προσαρμογή ΔΕΝ
  αφορά (μόνο Home) · καμία route.

## Ευρήματα

- Ε1 `.future` vs drift → listen+completer (γνωστό) · Ε2 retry-error idem.
- Ε3 DropdownMenu TextField → predicate με label (γνωστό trend).
- Ε4 excel 4.x: `TextCellValue.value` = δικό του TextSpan (toString) ·
  κελιά `Data?` nullable.
- Ε5 `const` record με DateTime → `final` · λείποντα imports.
- Ε6 6η κάρτα → lazy ListView: 3 υπάρχοντα tests ήθελαν scroll
  (`scrollUntilVisible`, όχι `ensureVisible` σε unbuilt node).
- Ε7 analyzer: unused import · `'$x'` interpolation info.

## Tests (+43 → 1356/1356)

- Νέα: DAO ledger 5 · repo ledger 3 · provider ledger 4 (search n/a —
  reuse) · service 7 (round-trip/`%PDF`/mapping) · controller 5 (fake
  picker + guard) · table 3 · section 11 (flow/persist/empty/error/
  excel/pdf/cancel/period/responsive/dark/semantics) · SPoT +5 ·
  exceptions +1.
- Ενημερωμένα: settings_page (6 tiles + τίτλος) · receipts_management
  (scroll) · 6 fakes · SPoT registries.
- Full suite **1356/1356** ✓ · `flutter analyze` No issues ✓.
- DESIGN §2.3/§4 (ενότητα + deps) · backup `backups/2026-09-29_stats_ledger/`.
