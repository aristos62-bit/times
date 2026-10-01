# Κεφ. 90 — Φίλτρο Η/Ε/Μ λίστας πρόσφατων (01-10-2026)

> `SegmentedButton` Ημέρας/Εβδομάδας/Μήνα πάνω από τη λίστα Εισαγωγής (default ημέρα, όριο 20).

## Υλοποίηση (update > create)

- DAO one-liner `watchSummariesBetween` → `_watchSummaries` (0 νέα SQL) · repo passthrough · 6 fakes stubs.
- State `recentPeriodFilterProvider` (default day) · `recentReceiptsStreamProvider` update in-place (day→byDay, week/month→between, `todayProvider`).
- UI: segments (SPoT labels) · κενά day→`noReceiptsForDay`, week/month→`noPricesForPeriod` · Φάση Β άθικτη.
- `DESIGN.md` §2.2.

## Ευρήματα (επανέλεγχος)

- In-memory φίλτρο απορρίφθηκε (έκρυβε παλιές) · `ChartPeriodSelector` βαρύ · `recentReceiptsEmpty` λάθος σε φίλτρο.
- Tests: 3 fixtures → today (2026-01-01 κρυμμένα) · `overrideWithBuild` για Timer (precedent statistics/home) · actions fixedToday.

## Επαλήθευση

- DAO 9/9 (+3) · stream 9/9 (+1) · λίστα+actions 14/14 · 360 overflow OK · analyze καθαρό.
- Backup `backups/2026-10-01_recent_filter/`.
