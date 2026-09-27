# Κεφάλαιο 58 — 5η πίτα «Ανά υποκατηγορία» (27-09-2026)

> Η sub-πίτα επέστρεψε μεταξύ κατηγορίας και τμήματος (ίδιο design/λογική
> με τις άλλες + Προσαρμογή Οθόνης). Αφαιρέθηκε πλήρως στο refactor (κεφ. 52)
> — επανήλθε με ξαναγραμμένο SQL 5 joins (το παλιό `items.sub_category_id`
> δεν υπάρχει).

## Αλλαγές (lib)

- `chart_totals`: +`SubCategoryTotal` · DAO +`watchTotalsBySubCategory`
  (5 joins, INNER, totalCents DESC/name ASC) · repo abstract+impl
  passthrough (`DataLoadException`) · provider family (`pieMaxSlices`) ·
  `chartSubCategoryTitle='Ανά υποκατηγορία'` (παλιά τιμή).
- Config: enum value + required field + defaults (0,1,**2**,3,4) + 3 switches
  (compiler-οδηγούμενα) · `home_page`/customization/controller αυτόματα
  (`ChartId.values`, id-generic) · settings impl: 5ο key + migration
  (παλιό 4-key → θέση 2 + shift ≥2) + αφαίρεση legacy fallback.
- Blocker: `build_runner` regen freezed (μόνο `home_chart_config.freezed`
  διέφερε — 0 drift noise).
- Αρχείο-όρια: DAO 446 · providers 400 · settings-impl 145 (<500).

## Tests (+4 → 1258/1258)

- DAO group (2 subs) · provider test · settings migration test ·
  strings edit+gate · settings corrupt/round-trip/save-key/legacy updates.
- `home_page`/`customization` 4→5 · overrides +1 ×6 sites (πλήρες app pump).
- Stubs ×6 fakes `implements ReceiptRepository` (4 αρχεία).

## Ευρήματα

- Ε1: customization standalone overflow 42px με 5 γραμμές (600px viewport) —
  `pumpExpanded` helper (800×2500, pattern home_page_test)· production
  (ListView) ανεπηρέαστο.
- Ε2: 2 fails app_router (pending-timer): η αιτία ΔΕΝ ήταν ο 60s Timer αλλά
  ο 3s `closeSafely`-timer — 2 override blocks (12-space) είχαν ξεφύγει από
  το replaceAll → πραγματική βάση → close timer. Μάθημα: replaceAll με
  mixed indentation θέλει grep-επαλήθευση.
- `home_chart_config_controller_test` / `receipt_repository_impl_test`:
  ΚΑΜΙΑ αλλαγή (επαληθευμένο με πλήρη ανάγνωση).
- DESIGN §2.1 (§2.1: 5 πίτες/1-2-3-4-5/5 streams/sub top-8) + §4 (βήμα 2,
  stale `:534`).
- Backup `backups/2026-09-27_subcategory_pie/` (23 αρχεία).
