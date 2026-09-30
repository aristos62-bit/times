# Κεφάλαιο 68 — Εξαγωγή καταλόγου (30-09-2026)

> 3ο κουμπί «Εξαγωγή καταλόγου» στην κάρτα Αντιγράφων (Q1 Excel · Q2 θέση ·
> Q3 πλήρης δομή με κενά κλαδιά · Q4 pattern filename). Q1–Q4 εγκεκριμένα.

## Data/UI (reuse)

- `CatalogExportService` (νέο, ~130 — όχι στο `statistics_export`
  των 520 γρ., κανόνας 7· precedent σκόπιμης μη-reuse §1.1): filename +
  builder (walk encounter-order, κενά κλαδιά, null-μονάδα, unmatched
  defensive, headers-only, `CatalogExportException` με `LogTag.backup`).
- `exportCatalog()` στον backup controller (`_guarded` reuse, +~35).
- SPoT +1 const / +2 strings / +1 message / +1 error / +1 exception
  (sealed — μέσα στο `app_exceptions.dart`).
- Headers reuse `field*` + 1 νέο (`catalogUnitAbbreviation`).

## Ευρήματα (το βασικό)

- **Ε1 `.future` σε StreamProvider = hang (Φάση 2 Βήμα 3, καταγεγραμμένο
  — μου διέφυγε σε v1-v3):** `categoryTreeStreamProvider.future` δεν
  ολοκληρώνεται ποτέ (4 timeouts 30s). Fix: pure `buildCategoryTreeNodes`
  (SPoT, reuse provider + controller) + repo-direct `.watchAll().first`
  (precedent `itemSearchController`/controller διαβάζει `appDatabase`).
- **Ε2 widget FakeAsync + one-shot reads = αδιέξοδο:** 4 παραλλαγές
  (file/mem DB, runAsync, pumps) — το op δεν ολοκληρώνεται ποτέ στη ζώνη,
  ενώ περνάει 11/11 σε πραγματικό async. Το E2E widget test ΑΦΑΙΡΕΘΗΚΕ
  (τεκμηριωμένα στο αρχείο): κάλυψη από controller (op→picker→bytes) +
  service (περιεχόμενο) + button-exists· precedent: ούτε το tap του
  «Εξαγωγή αντιγράφου» τεστάρεται.
- Ε3/E4 test-μηχανικά: `createdAt` non-null (όχι null) · decode asserts
  με `TextCellValue`-check (pattern stats, όχι interpolation).

## Tests (+16 → 1519/1519)

- Νέα: service 8 · SPoT 3 · controller 4 · section 1 (ύπαρξη κουμπιού).
- Full suite **1519/1519** ✓ (και κονσόλα χρήστη, ένα-ένα) ·
  `flutter analyze` No issues ✓.
- DESIGN §2.3 (backup ροή) · backup `backups/2026-09-30_catalog_export/`.
