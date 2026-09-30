# Κεφ. 72 — SPoT συνόλου γραμμής `line_total.dart` (30-09-2026)

> Ο τύπος `((p−d)×q).round()` σε 5 σημεία → 1 pure function. Χωρίς bug, χωρίς ρίσκο δεδομένων (stored αλήθεια ήδη ενιαία) — διακοπή proliferation.

## Ευρήματα (εξαντλητική σάρωση `.round()`)

- 5 σημεία ίδιου τύπου: DAO insert:151 + update:207-211 (stored) · draft getter (display) · export `netTotalCents(row)` + `purchasesTotalsOf` loop (display, εσωτερικό dup).
- Εκτός scope (ρητά, άλλοι υπολογισμοί): αντίστροφα `(T/Q)` + `(D/Q)`, `p−d` displays, chart-scaling.
- Doc-gap (εκτός scope): §3:502 «downstream ΜΟΝΟ SUM(stored)» vs Dart-recompute στα stats — θέλει query-αλλαγές, ξεχωριστή πρόταση.

## Αλλαγές (0 νέα strings, 0 νέα errors)

1. Νέο `lib/core/utils/line_total.dart` (~25 γρ., pure, `library;`).
2. 5 αντικαταστάσεις: DAO ×2 · draft getter (έφυγε νεκρό `netUnitCents`) · export ×2 · docstrings → pointάρουν εκεί.
3. `tables.dart` σχόλιο + regen `.g.dart` (diff = μόνο σχόλιο).
4. `DESIGN.md` §3 (:502 SPoT-διατύπωση, :503 writer-διατύπωση).
5. Tests: νέο `test/core/utils/line_total_test.dart` (+6, pure, κατοπτρικά values DAO tests).

## Επαλήθευση (30-09-2026)

- Νέο + DAO + export **43/43** ✓ · repos + prefill + flow **34/34** ✓ · `flutter analyze` No issues ✓.
- Backup `backups/2026-09-30_line_total/` (3 lib + DESIGN + tables + oldsessions).
