# Φάση 3 — Βήμα 6: Validation μέσω SPoT validators

> Ημερομηνία έναρξης: 20-09-2026 · Κατάσταση: Κλειστό
> Οι κανόνες εγκυρότητας τιμής/ποσότητας/μονάδας/προμηθευτή/γραμμών και
> ονομάτων συγκεντρώνονται σε SPoT validators (`domain/validators/`) και
> ενεργοποιούνται σε τρία σημεία: inline στη φόρμα, στο κουμπί αποθήκευσης
> και ως safety-net στον controller. Υλοποιήθηκε σε υποβήματα 6α–6ζ (+6η
> τεκμηρίωση), ένα-ένα με backup, tests και ρητό «επόμενο».

---

## 1. Υποβήματα

| Υποβήμα | Περιεχόμενο | Tests (σύνολο) |
|---|---|---|
| 6α — SPoT μηνύματα | `AppErrors` +9: `priceMustBePositive`, `priceTooLarge`, `quantityMustBePositive`, `quantityTooLarge`, `quantityMustBeInteger`, `unitRequired`, `supplierRequired`, `receiptLinesRequired`, `nameExists` · `AppConstants.fieldErrorMaxLines=3` · σχόλιο: το `validationMinPrice` συγκρίνεται σε ΛΕΠΤΑ | +10 (587) |
| 6β — `ReceiptValidator` | `domain/validators/receipt_validator.dart`: static, καθαρός, contract `String?` (όπως `NameValidator`). `validateUnit` · `validatePriceCents` · `validateQuantity` · `validateLine` · `validateLineCount` (επαναχρησιμοποιεί `AppMessages.receiptLinesLimitReached`) · `validateReceipt` · `isIncompleteNumber` | +39 (626) |
| 6γ — Controller safety-net | `DraftReceiptLine.unitAllowsDecimal` (προαιρετικό, default `true`) · `addDraftLine` αγνοεί άκυρη γραμμή + log `[UI][ERROR]` · `saveReceipt` validation ΠΡΙΝ το `isSaving` → log + `SaveReceiptException` · `createSupplier` περνά από `NameValidator` | +14 (640) |
| 6δ — UI φόρμας | `errorText`/`errorMaxLines` στα `CurrencyTextField`/`QuantityTextField` · `unit_quantity_price_section`: `_quantityCheck`/`_priceCheck` μέσω validator (κενό και «5,» χωρίς σφάλμα), hint μονάδας, `unitAllowsDecimal` στη γραμμή | +19 (659) |
| 6ε — Save + προμηθευτής | `save_receipt_button`: `canSave` από `validateReceipt` + hint `supplierRequired` · `receipt_header_section`: `NameValidator` πριν το DB + snackbar σφάλματος · **fix** `SearchableDropdownField.displayStringForOption` (βλ. §3) | +10 (669) |
| 6ζ — Dialog νέου είδους | `new_item_flow_dialog`: inline `nameRequired`/`nameTooLong`/`nameExists` στο «+» Κατηγορίας/Υποκατηγορίας (όχι snackbar μέσα στο dialog) | +8 (677) |
| 6η — Τεκμηρίωση | DESIGN §2.2/§2.4/§2.4.1/§5 · NOTEs σε `app_errors`/`app_exceptions` · αυτό το κεφάλαιο | — |

## 2. Αποφάσεις (εγκρίθηκαν από τον χρήστη πριν το 6α)

1. **Save-time σφάλμα** = `SaveReceiptException` + log του λόγου (όχι νέα
   `ValidationException` — θα έσπαγε το compile-time mapping του sealed
   `AppException` και 2 υπάρχοντα tests).
2. `DraftReceiptLine.unitAllowsDecimal`: **προαιρετικό** (default `true`) —
   11 fixtures σε 6 test αρχεία μένουν άθικτα.
3. Inline σφάλματα μέσω **`errorText`** στα shared fields (a11y, wrapping,
   dark mode από το theme).
4. 6ζ (dialog) μπήκε στο Βήμα 6, χωρίς αλλαγή της λογικής δημιουργίας.
5. `lineTotalCents == 0` (π.χ. 0,01 € × 0,004) → **αναβολή στο Βήμα 7**:
   ο υπολογισμός είναι SPoT του `ReceiptLineDao` και δεν διπλογράφεται.
6. Housekeeping (βλ. §6) μετά το Βήμα 6, ξεχωριστό βήμα.
7. Έξοδος με μη αποθηκευμένες γραμμές: προγραμματίζεται ως «Βήμα 7β».

## 3. Ευρήματα / περιστατικά

1. **`backupFileNamePattern` αλλοιώθηκε** κατά την επεξεργασία του
   `app_constants.dart` (`…_Hxmlns` αντί `…_HHmmss`)· το έπιασε
   `app_constants_test` (2 failures). Διορθώθηκε στο 6α· το `git diff`
   επιβεβαίωσε ότι δεν άλλαξε τίποτα άλλο.
2. **Διπλή επικεφαλίδα** `// ─── Numeric / Precision ───` στο
   `app_constants.dart` (λάθος των οδηγιών μου: το block «Νέο» περιείχε την
   επικεφαλίδα ενώ η αρχική έμενε) — διορθώθηκε στο 6γ.
3. **Προϋπάρχον bug στο `SearchableDropdownField`** (ανιχνεύθηκε από το test
   HB4 του 6ε): το `RawAutocomplete._select` γράφει στο πεδίο το
   `displayStringForOption(επιλογή)`, default `toString()`
   («Instance of '_CreateEntry<Supplier>'»). Το `_create` το αντικαθιστούσε
   με label μόνο σε επιτυχία· με `onCreate → null` (άκυρο όνομα, σφάλμα DB)
   το πεδίο έμενε με αυτό το κείμενο. Fix: ρητό `displayStringForOption`
   (αποτέλεσμα → label, «+» → query). Το αρχείο ήταν 497 γρ. → οι `_Entry`
   κλάσεις μεταφέρθηκαν σε `part` `searchable_dropdown_entry.dart`
   (κύριο αρχείο 491 γρ.).
4. **Tests με DB σε background isolate**: η `NativeDatabase` τρέχει σε
   πραγματικό χρόνο — τα dup-check tests του 6ζ (Z2–Z4) χρειάστηκαν
   `runAsync` πριν το `pumpAndSettle` (ίδιο μοτίβο με `settleSearch` του
   `item_search_field_test`). Το Z3 διορθώθηκε: `enterText` με ίδιο κείμενο
   δεν πυροδοτεί `onChanged` (το πεδίο κρατά πλέον το query).
5. **Block tests στη λάθος θέση** (header test 6ε) — αντικαταστάθηκε το
   αρχείο με σωστά τοποθετημένο περιεχόμενο. Δεν υπήρξε πρόβλημα στον
   κώδικα `lib`.
6. **Κλείδωμα `build\native_assets\windows\sqlite3.dll`** από ανοιχτή
   διεργασία → το `flutter test` δεν ξεκινούσε· λύθηκε κλείνοντας την
   εφαρμογή/διεργασίες και διαγράφοντας τον φάκελο `build\native_assets`.

## 4. Αρχεία (γραμμές μετά το Βήμα 6)

| Αρχείο | Σημειώσεις |
|---|---|
| `domain/validators/receipt_validator.dart` (νέο, 104) | SPoT validator, καθαρός |
| `core/constants/app_errors.dart` (81) · `app_constants.dart` (140) | +9 μηνύματα · +`fieldErrorMaxLines` |
| `presentation/price_entry/state/receipt_form_state.dart` (101) | +`unitAllowsDecimal` |
| `.../controllers/receipt_form_controller.dart` (238) | safety-net `addDraftLine`/`saveReceipt`, `createSupplier` |
| `.../widgets/unit_quantity_price_section.dart` (325) | inline validation + hint μονάδας |
| `.../widgets/save_receipt_button.dart` (102) · `receipt_header_section.dart` (148) | `canSave` + hint · έλεγχος ονόματος |
| `.../widgets/new_item_flow_dialog.dart` (317) | inline σφάλματα «+» |
| `presentation/shared/currency_text_field.dart` (116) · `quantity_text_field.dart` (128) | +`errorText` |
| `presentation/shared/searchable_dropdown_field.dart` (491) · `searchable_dropdown_entry.dart` (νέο, 21) | fix + part αρχείο |
| Tests (νέα) | `receipt_validator_test` · `receipt_form_controller_validation_test` · `unit_quantity_price_section_validation_test` · `new_item_flow_dialog_validation_test` · `searchable_dropdown_field_create_test` |
| Tests (αλλαγές) | `app_errors_test` · `app_constants_test` · `receipt_form_state_test` · `currency/quantity_text_field_test` · `receipt_header_section_test` · `save_receipt_button_test` |

Backups: `backups/*_before_fase3_b6a_*`, `*_b6a_fix_*`, `*_b6c_*`, `*_b6d_*`,
`*_b6e_*`, `*_b6z_*`, `*_b6h_*`.

## 5. Verification

`flutter test` **677/677** ✓ (577 → 587 → 626 → 640 → 659 → 669 → 677) ·
`flutter analyze` **No issues** ✓ · κανένα νέο ή τροποποιημένο `.dart`
>500 γρ.

**CORRECTION → κεφάλαιο 14** (αρχεία `…_price_entry_lines.md` και
`…_price_entry_lines_2.md`): τα placeholders `‹N›/‹N›` και `‹No issues›`
σημαίνουν `flutter test` **577/577** ✓ (τοπικά, 20-09-2026) και
`flutter analyze` **No issues** ✓ (GitHub Actions «Flutter CI» run #30,
commit `4093c9e`). Το TOC και η σύνοψη του root ενημερώθηκαν αντίστοιχα.

## 6. Ανοιχτά (δεν υλοποιήθηκαν σε αυτό το Βήμα)

- **Housekeeping** (ξεχωριστό βήμα): (α) split των test αρχείων >500 γρ.
  (`receipt_form_controller_test.dart` 667, `searchable_dropdown_field_test.dart`
    528) — παραβίαση κανόνα 7 του AGENTS· (β) το κεφάλαιο 14 υπάρχει σε δύο
         αρχεία για το ίδιο κεφάλαιο (το TOC δείχνει το παλαιότερο, χωρίς το 5ε-3).
- **Έξοδος με μη αποθηκευμένες γραμμές** (§2.2 «Ημιτελής καταχώρηση»,
  `ConfirmDialog` + `PopScope`) → προτεινόμενο «Βήμα 7β».
- **`lineTotalCents == 0`** (`(priceCents * quantity).round()`, π.χ.
  0,01 € × 0,004) → Βήμα 7, με κοινό SPoT υπολογισμό συνόλων.
- **`onChanged` στο `SearchableDropdownField`**: τα inline μηνύματα του «+»
  δεν σβήνουν καθώς ο χρήστης πληκτρολογεί (σβήνουν σε επιλογή/επόμενη
  επιτυχία)· μετά από «υπάρχει ήδη» το overlay ξανανοίγει μόνο με αλλαγή
  κειμένου. Προαιρετικό (χρειάζεται χώρος στο όριο των 500 γρ.).
- **Write-time conflicts (FK/UNIQUE)**: το `loadDataFailed` καλύπτει ακόμα
  τα σφάλματα εγγραφής καταλόγου· ειδικό μήνυμα στη Φάση 4. Επίσης το
  `_createCategory`/`_createSubCategory` του dialog δεν πιάνει
  `DataLoadException` του insert (προϋπάρχον).

## 7. Επόμενο

Φάση 3, Βήμα 7: Placeholder λίστα αποδείξεων (`recent_receipts_list.dart`,
DESIGN §4 Φάση 3 Βήμα 7).