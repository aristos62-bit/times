# Κεφάλαιο 36 — Έκπτωση γραμμής + prefill τελευταίας τιμής

**Ημερομηνία:** 25-09-2026 · **Κατάσταση:** Κλειστό

## Αίτημα χρήστη

1. Πεδίο έκπτωσης (−€) ανά γραμμή: αν συμπληρωθεί αφαιρείται από την τιμή
   μονάδας, τελικό γραμμής `(τιμή−έκπτωση)×ποσότητα.
2. Είδος με ιστορικό → prefill τιμής + έκπτωσης από την τελευταία γραμμή.

## Υλοποίηση

- **Schema** (`schemaVersion` 3): `discountCents INTEGER NOT NULL DEFAULT 0`
  · `lineTotalCents=((p−d)×q).round()` (SPoT DAO) · migration `from<3
  addColumn` + `from==1` παλιό · build_runner regen `.g.dart`.
- **Data**: `ReceiptLineDao` (`discountCents=0`, recompute, νέο
  `getLatestByItemId` join+`date DESC,id DESC`) · `ReceiptLineInput+
  discountCents` · repo passthrough · `latestReceiptLineProvider`
  (FutureProvider.family, one-shot, σιωπηλό error).
- **Domain/UI**: `validateDiscountCents` + `validateLine(...,{=0})` ·
  `Draft.discountCents=0` + `netUnitCents/netTotalCents` (display-mirror) ·
  `DiscountField` (dumb) + section (unit-mode μόνο, `_centsCheck` shared,
  price next→discount done, prefill gate: match/κενά/typing/total) ·
  draft display `«τιμή −έκπτωση (σύνολο net)»` (εξαίρεση Δ2-β) ·
  `unit_section_checks.dart` part (section 512→452, κανόνας 7).
- **SPoT**: `fieldDiscount` + `discountTooLarge`/`discountNegative`
  (+gates) · 0 constants/messages · **Δ-stat**: μοναδιαία στατιστικά ΠΑΝΤΑ
  με `p−d` (DESIGN §2.1/§3).
- **Ευρήματα υλοποίησης**: build_runner ΞΕΧΑΣΤΗΚΕ αρχικά (undefined
  getter) · interface-decl έλειπε η γραμμή δήλωσης · `valueOrNull`
  ανύπαρκτο στο Riverpod 3 (→`.value`) · S1 `€×2` (assertion παλιάς
  συμπεριφοράς) · migration-e2e έσπασε από τη νέα στήλη (→DROP COLUMN για
  αληθινό v1-shape, τεστάρει πια το 1→3 path).

## Tests

- ΝΕΟ `line_prefill_test.dart` (6: happy/mismatch/typed-gate/total/
  no-history/dark) · επεκτάσεις validator(10)/DAO(9)/repo/update/stream/
  draft/section(D1-D4)/controller(save-mapping/safety-net/edit-load) ·
  μηχανικά: 31 literals + 6 fakes + 2 gates · S1 διορθώθηκε (2×€).
- Full suite: **995/995** ✓ (+43) · `--timeout 60s` ·
  `flutter analyze` **No issues** ✓.

## Backup/Docs

- `backups/2026-09-25_discount_prefill/` — 30 αρχεία (πριν τις αλλαγές).
- `DESIGN.md`: §3 (διάγραμμα/formula/discount/Δ-stat) + §2.1/§2.2
  (machine/validation/widgets) + §5.
