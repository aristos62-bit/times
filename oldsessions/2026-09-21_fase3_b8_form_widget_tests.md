# Φάση 3 — Βήμα 8: Widget tests στη φόρμα (gap-fill + housekeeping splits)

> Ημερομηνία έναρξης: 21-09-2026 · Κατάσταση: Κλειστό
> Έλεγχος κενών/ενοποίηση της Φάσης 3: flow widget tests (full-flow +
> double-save), dark gap-fill (5 test αρχεία), semantics group (§1.6) και
> housekeeping splits των 3 test αρχείων >500 γρ. (κανόνας 7). Mηδέν αλλαγές
> σε `lib/`. Υλοποιήθηκε σε Υποβήματα 1–7, ένα-ένα με backup, tests και ρητό
> «επόμενο» από τον χρήστη.

---

## 1. Υποβήματα

| Υποβήμα | Περιεχόμενο | Tests (σύνολο) |
|---|---|---|
| 1 — Backup | 10 `.bak` στο `backups/2026-09-21_fase3_b8_form_widget_tests/` (εμπλεκόμενα test αρχεία) | — |
| 2 — Flow tests | `price_entry_form_flow_test.dart` (νέο, ~385 γρ.): **F1** πλήρης ροή (seed Μάρκος/Κιλό/Τεμάχιο/Γάλα/Ψωμί, live search + tap overlay, σύνολο 3,70 €/370¢) · **F2** double-save μέσω `_BlockingReceiptRepo` (Completer-gate πριν το insert) | +2 |
| 3 — Dark gap-fill | 5 test αρχεία με πρότυπο V12 (`ThemeData? theme` → `MaterialApp(theme: theme)`), 1 dark test ανά αρχείο · backup `backups/2026-09-21_fase3_b8_dark_gapfill/` | +5 |
| 4 — Semantics | `price_entry_semantics_test.dart` (νέο, 281 γρ.) — **S1** `PriceEntryPage` semantics-enabled (Α1 override, κανένα crash) · **S2** `supplierRequired` liveRegion (SaveReceiptButton) · **S3** `unitRequired` liveRegion (UnitQuantityPriceSection, χωρίς default μονάδα) · **S4** `nameExists` liveRegion (dialog «+» duplicate) | +4 |
| 5–7 — Splits | 3 test αρχεία >500 γρ. → **8 αρχεία** (αρχικό όνομα = μέρος 1, καμία διαγραφή): `receipt_form_controller_test` 675→3 (state · create_supplier · save_receipt) · `stream_providers_test` 565→3 (catalog · search · receipts) · `searchable_dropdown_field_test` 529→2 (pure · integration) · backup `backups/2026-09-21_fase3_b8_housekeeping_splits/` | 0 (±0) |
| 8 — Full verify | `flutter test` **710/710** ✓ (+11) · `flutter analyze` **No issues** ✓ · κανένα `.dart` >500 γρ. | +11 |
| 9 — Τεκμηρίωση | oldsessions root (TOC + σύνοψη) + αυτό το κεφάλαιο · DESIGN.md **δεν** άλλαξε (κανόνας 8) | — |

## 2. Αποφάσεις (εγκρίθηκαν από τον χρήστη πριν την υλοποίηση)

1. **Σειρά υποβημάτων**: flow → dark → semantics (ο χρήστης επέλεξε
   «semantics» έναντι «splits» ως επόμενη σειρά)· στο τέλος και τα splits
   «όλα μαζί» (ρητό OK).
2. **Dark gap-fill — πρότυπο V12**: κάθε εμπλεκόμενο test αρχείο παίρνει
   `ThemeData? theme` στις `pump…` helpers και `MaterialApp(theme: theme)` +
   **1 dark test** ανά αρχείο (dark mode §1.5) — χωρίς `theme:` param, μηδέν
   αλλαγές στην ουσία των tests.
3. **Flow F1/F2**: override **ΜΟΝΟ** `appDatabaseProvider` (πραγματική
   in-memory βάση)· `settleSearch` idiom `pump(300ms) → runAsync(150ms) →
   pumpAndSettle` για drift/background isolate· runAsync **πριν** πάτημα
   save/απελευθέρωση gate (spinner)· viewport 800×1600 στο flow.
4. **Semantics**: `tester.ensureSemantics()` + κλείσιμο του `SemanticsHandle`
   **μέσα στο test body** (βλ. εύρημα 1)· έλεγχος μέσω
   `SemanticsData.flagsCollection.isLiveRegion` (βλ. εύρημα 2)· S1 με Α1
   override (κενή `recentReceiptsStreamProvider`), S4 με `runAsync` πριν το
   duplicate-check (βλ. εύρημα 3).
5. **Splits — ονομασία**: το αρχικό όνομα αρχείου παραμένει ως «μέρος 1»
   (επαναγραφή) και τα υπόλοιπα γίνονται νέα αδερφά `…_xxx_test.dart` —
   **καμία διαγραφή**, κανένας κίνδυνος για test-discovery, πλήθος tests
   αμετάβλητο. Κάθε αρχείο φέρει τα δικά του imports/helpers.

## 3. Ευρήματα / περιστατικά

1. **`SemanticsHandle` dispose**: το `addTearDown(handle.dispose)` ΔΕΝ αρκεί —
   ο ελεγκτής `WidgetTester._verifySemanticsHandlesWereDisposed` τρέχει στο
   `_endOfTestVerifications` **πριν** τα tearDowns → «A SemanticsHandle was
   active at the end of the test». Fix: `handle.dispose()` ρητά στο τέλος του
   test body.
2. **`hasFlag` deprecated** (μετά `3.32.0-0.0.pre`): αντικατάσταση με
   `SemanticsData.flagsCollection.isLiveRegion` — η νέα κλάση `SemanticsFlags`
   έχει δηλωτικές ιδιότητες (`isLiveRegion`, `isButton`, …), όχι
   `Set.contains`.
3. **Duplicate-check στο «+» του dialog** τρέχει στο background isolate του
   drift → χωρίς `runAsync` το `nameExists` έφτανε ΑΡΓΟΤΕΡΑ από το assert
   (`find.text` = 0 widgets, αν και ο log «[UI] Απόρριψη… διπλότυπο» έδειχνε
   πως το path εκτελέστηκε). Fix: `runAsync(delayed)` μετά το tap (idiom
   `settleSearch`).
4. **Splits — μηδέν λογικές αλλαγές**: μόνο 1 περιττό import (`dart:async`
   στο integration αρχείο, όλα τα σύμβολα έρχονται από το `flutter_test`) —
   έπιασε το full-analyze. Οι γραμμές των αρχείων: 267/130/357 · 170/277/201 ·
   287/275 (όλα <500).
5. **Υφιστάμενα siblings**: στους φακέλους υπήρχαν ήδη splits προηγούμενων
   φάσεων (`receipt_form_controller_validation_test`,
   `searchable_dropdown_field_show_all_test` κ.ά.) — δεν πειράχτηκαν.

## 4. Αρχεία (γραμμές μετά το Βήμα 8)

| Αρχείο | Σημειώσεις |
|---|---|
| `test/presentation/price_entry/price_entry_form_flow_test.dart` (νέο, ~385) | F1 full-flow + F2 double-save |
| `test/presentation/price_entry/semantics/price_entry_semantics_test.dart` (νέο, 281) | semantics §1.6 (S1–S4) |
| Tests (dark gap-fill) | `receipt_header_section_test` (336) · `save_receipt_button_test` (460) · `item_search_field_test` (383) · `draft_lines_list_test` (124) · `unit_quantity_price_section_test` (375) |
| `test/…/controllers/receipt_form_controller_test.dart` (267) | state mutations (ημερομηνία/προμηθευτής/καλάθι) |
| `test/…/controllers/receipt_form_controller_create_supplier_test.dart` (130, νέο) | createSupplier + `_FailingSupplierRepo` |
| `test/…/controllers/receipt_form_controller_save_receipt_test.dart` (357, νέο) | saveReceipt/resetForm + `_FailingReceiptRepo`/`_BlockingReceiptRepo` |
| `test/data/providers/stream_providers_test.dart` (170) | catalog + family list |
| `test/data/providers/stream_providers_search_test.dart` (277, νέο) | search families |
| `test/data/providers/stream_providers_receipts_test.dart` (201, νέο) | receipt streams |
| `test/presentation/shared/searchable_dropdown_field_test.dart` (287) | gated watch/debouncer/create |
| `test/presentation/shared/searchable_dropdown_field_integration_test.dart` (275, νέο) | icons/integration/responsive |

Backups: `backups/2026-09-21_fase3_b8_form_widget_tests/` (10) ·
`backups/2026-09-21_fase3_b8_dark_gapfill/` ·
`backups/2026-09-21_fase3_b8_housekeeping_splits/` ·
`backups/2026-09-21_fase3_b8_docs/` (oldsessions.md).

## 5. Verification

`flutter test` **710/710** ✓ (699 → 710, +11: +2 flow · +5 dark · +4 semantics,
splits 0±0) · `flutter analyze` **No issues** ✓ · κανένα `.dart` >500 γρ.
(κανόνας 7) · **0 αλλαγές σε `lib/`** (tests-only).

## 6. Ανοιχτά (δεν υλοποιήθηκαν σε αυτό το Βήμα)

- **Έξοδος με μη αποθηκευμένες γραμμές** (§2.2 «Ημιτελής καταχώρηση»,
  `ConfirmDialog` + `PopScope`) → «Βήμα 7β» → αναδρομικά μετά τη Φάση 3.
- **Προαιρετικό `onChanged` στο `SearchableDropdownField`**: τα inline
  μηνύματα του «+» δεν σβήνουν κατά την πληκτρολόγηση.
- **Ενοποίηση του διπλού κεφαλαίου 14** oldsessions (B5: `…_price_entry_lines`
  + `…_price_entry_lines_2`).

## 7. Επόμενο

Η Φάση 3 κλείνει ως πλήρης → **Φάση 4 (Ρυθμίσεις)**. Ο έλεγχος βρίσκεται σε
κάθε Βήμα: κλείνει μόνο με ρητό OK, tests + analyze πράσινα και ενημέρωση
τεκμηρίωσης.