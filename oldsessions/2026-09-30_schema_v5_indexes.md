# Κεφ. 75 — Migration v4→v5: 3 indexes (30-09-2026)

> Πρώτη πραγματική migration από το baseline. Full-scan σε receipt_id/date/supplier_id → 3 single-column indexes. Δεδομένα άθικτα.

## Σχεδιασμός (Q1–Q3 ✓)

- **Q1**: 3 single (`idx_receipt_lines_receipt_id` · `idx_receipts_date` · `idx_receipts_supplier_id` via `@TableIndex`) — range + joins.
- **Q2**: raw `CREATE INDEX IF NOT EXISTS` (το `m.createIndex` είναι re-run-unsafe — verified στην πηγή drift 2.35· rename-divergence αποδείχθηκε αβλαβής).
- **Q3**: strict μένει + οδηγία fresh export (v4 backups reject).
- Extras υλοποίησης: log interpolation `$schemaVersion` · V3-test rename («προηγούμενη έκδοση»).

## Αλλαγές

tables + app_database (v5 + step + logs) + app_migration_test (T1→5, M1, M2) + regen `.g.dart` (diff: μόνο τα 3 indexes — names ταυτίζονται με step) · `DESIGN.md` §3 (λίστα 4 indexes + schema v4→v5).

## Επαλήθευση (30-09-2026)

- Migration **4/4** ✓ (M2: indexes + γραμμή άθικτη + version 5) · app_database 4/4 ✓ · backup 22/22 ✓ · `flutter analyze` No issues ✓.
- Backup `backups/2026-09-30_schema_v5_indexes/` (4 lib/test + DESIGN + oldsessions).

## ⚠️ Μετεγκατάσταση συσκευής

Πρώτο open μετά το update → 3 indexes (ms, άθικτα δεδομένα). Μετά: **φρέσκο export** (τα v4 backups απορρίπτονται).
