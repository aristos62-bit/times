# Κεφάλαιο 66 — Φίλτρο καταλόγου 3 επιπέδων στις αναλύσεις (29-09-2026)

> Τελική πρόταση (Option A + Q1–Q5, όλα εγκεκριμένα): dumb `CatalogFilterField`
> (Κατηγορία→Υποκατηγορία→Τμήμα) shared σε 2η/3η ανάλυση · 3 nullable ids στο
> `PeriodPurchasesQuery` → προαιρετικά SQL WHERE · ισχύει σε οθόνη + export.

## Data/UI (ίδιο λεπτό layer)

- `catalog_filter.dart` (νέο, <500): `SearchableDropdownField` show-all +
  `onCleared` (reuse in-memory families, 0 νέα queries) · κενό = Όλα (hints,
  Q1) · αλλαγή γονέα μηδενίζει παιδιά (keyed rebuilds, Q2) · παιδί disabled
  με hint χωρίς γονέα (σταθερό layout, Q5) · κουμπί «Όλες» (reuse
  `clearReceiptFilter`) · τοπικό state, όχι persist (Q5) · επιλογή ανεβαίνει
  με `onChanged` (0 provider-reads, §2.0).
- DAO/repo/provider: `watchPeriodPurchases` +3 προαιρετικά (`categoryId`,
  `subCategoryId`, `itemGroupId` — fixed στήλες, variables τιμές) · query
  +3 nullable (null = Όλα) · 6 fakes ενημερωμένα (2 `_Failing…` + 4 forwarders).
- SPoT +3 (`statsFilterAllCategories/SubCategories/ItemGroups`).

## Ευρήματα

- Ε1 record query 3→6 πεδία: όλα τα literals θέλουν ρητά nulls (2 canned +
  helper).
- Ε2 detail +200px → overflow 40px στα 800×600 (production ListView ΟΚ):
  test-only fix — `SingleChildScrollView` στο `wrap()` (4 scaffolds) +
  `ensureVisible` στα 2 export (κουμπιά κάτω από fold).
- Ε3 `TextField.enabled` null = ενεργό (όχι true) — assertion στο νέο test.
- Ε4 Material DropdownMenu internals ΔΕΝ restyle (2 reverts — απόφαση).

## Tests (+8 → 1454/1454)

- Νέα: DAO 3 (χωρίς φίλτρο/κατηγορία/συνδυασμός+άσχετο→[]) · provider 1
  (κατηγορία→μόνο τα είδη της) · widget 3 (αρχικό/enable/clear) · SPoT +1.
- Όλα τα 10 επιλεγμένα + full suite **1454/1454** ✓ (επαληθευμένα και στην
  κονσόλα χρήστη, ένα-ένα) · `flutter analyze` No issues ✓.
- DESIGN §2.3 (φίλτρο + shared 3η) · backup `backups/2026-09-29_catalog_filter/`.
