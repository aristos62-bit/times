# Φάση 3 — Βήμα 5: Εισαγωγή γραμμών απόδειξης (Unit · ποσότητα · τιμή · save flow)

> Ημερομηνία έναρξης: 18-09-2026 · Κατάσταση: Κλειστό
> Η PriceEntryPage αποκτά ολόκληρη τη ροή του «καλαθιού»: επιλογή μονάδας
> (show-all dropdown), ποσότητα και τιμή με SPoT parse/format, λίστα draft
> γραμμών και ατομική αποθήκευση της απόδειξης. Υλοποιήθηκε σε υποβήματα
> 5α–5δ + 5ε (5ε-1…5ε-3: κλείσιμο αποκλίσεων από το πλάνο).

---

## 1. Υποβήματα

| Υποβήμα | Περιεχόμενο |
|---|---|
| 5α — Numeric fields & config | `decimal_input_formatter.dart` (κοινός formatter: μοναδικός διαχωριστής `.`/`,`, όριο δεκαδικών) · `currency_text_field.dart` (`parseCents`/`formatCents`, όριο `maxPriceCents`) · `quantity_text_field.dart` (`parseQuantity` 3 δεκ., integer-only mode, όριο `maxQuantity`) · `AppConstants`: `priceMaxLength=10`, `quantityMaxLength=11`, `maxPriceCents=9999999` (€99.999,99), `maxQuantity=1000000.0` |
| 5β — Dropdown extension + units | `SearchableDropdownField`: `initialValue`, `showAllWhenEmpty` + `allOptionsProvider` (show-all-on-focus, Δ1) · `unitSearchProvider` (family, in-memory πάνω στο `watchAll`, κενό query → `Stream.value([])`) · `unitsStreamProvider` ως πηγή «όλων» |
| 5γ — State · Section · Draft list | `DraftReceiptLine` (plain, όχι Freezed) + `draftLines` στο `ReceiptFormState` · `addDraftLine`/`removeDraftLine` · `unit_quantity_price_section.dart` (default unit από `Item.defaultUnitId`, prefill ποσότητας Δ8, περικοπή δεκαδικών σε integer-only μονάδα §2.2:218) · `draft_lines_list.dart` (χωρίς line totals, Δ2) · `price_entry_page.dart` (LayoutBuilder: στενή→Column, φαρδιά→Row) · αφαίρεση `priceEntryLinesComingSoon` · fix clear-on-drop στο `item_search_field` |
| 5δ — Save & feedback | `saveReceipt` (`isSaving` double-tap guard · defensive guards supplier/κενό καλάθι → `SaveReceiptException` · `ref.mounted` μετά το await · επιτυχία → `resetForm`, αποτυχία → drafts μένουν + rethrow) · `save_receipt_button.dart` (disabled-OR, feedback ΜΟΝΟ στο widget) |
| 5ε-1 — `onCleared` | Νέο προαιρετικό callback στο `SearchableDropdownField`: fire-once όταν επιλογή/προεπιλογή παύει να ισχύει από επεξεργασία κειμένου. Στο section: `onCleared → _unit = null` (πριν, σβήσιμο του πεδίου μονάδας άφηνε το Add ενεργό με αόρατη μονάδα) |
| 5ε-2 — Όριο καλαθιού | `addDraftLine` αγνοεί γραμμή στο `maxReceiptLines` (100) — safety-net + log · section: Add ανενεργό + inline `AppMessages.receiptLinesLimitReached(max)` |
| 5ε-3 — Unit search σε συντομογραφία | `unitSearchProvider`: match (κανονικοποιημένο, `contains`) στο όνομα Ή στη συντομογραφία, ένα `where` με `\|\|` (χωρίς διπλότυπα). Πριν, «λτ» (Λίτρο) και «χλτ» (Χιλιοστόλιτρο) δεν έβρισκαν τίποτα |

## 2. Αποκλίσεις από το πλάνο (Μέρος Γ) και πώς λύθηκαν

1. Το κουμπί αποθήκευσης υλοποιήθηκε ως ξεχωριστό `save_receipt_button.dart`
   (το πλάνο το έβαζε στο `draft_lines_list`) — SoC, εγκεκριμένο.
2. Το `onCleared` (5β), το όριο `maxReceiptLines` στο `addDraftLine` (5γ) και
   το match συντομογραφίας στο `unitSearchProvider` (5β) είχαν παραλειφθεί —
   υλοποιήθηκαν στο 5ε-1, 5ε-2, 5ε-3 αντίστοιχα.
3. Ονόματα strings διαφέρουν ελαφρά από το πλάνο (`draftLinesEmpty`,
   `removeDraftLine`)· δεν προστέθηκε `errorInvalidAmount` (το validation
   ανήκει στο Βήμα 6). Ο private `_reset` του πλάνου έγινε public `resetForm`.

## 3. Αρχεία 5ε (νέα/αλλαγές)

| Αρχείο | Σημειώσεις |
|---|---|
| `presentation/shared/searchable_dropdown_field.dart` | +`onCleared` (497 γρ.) |
| `presentation/price_entry/widgets/unit_quantity_price_section.dart` | +`onCleared`, +`atLimit` watch (`select`) + μήνυμα ορίου |
| `presentation/price_entry/controllers/receipt_form_controller.dart` | όριο στο `addDraftLine` |
| `core/constants/app_messages.dart` | +`receiptLinesLimitReached(int max)` |
| `data/providers/stream_providers.dart` | `unitSearchProvider`: όνομα Ή συντομογραφία |
| Tests | `searchable_dropdown_field_selection_test.dart` (νέο) · `receipt_form_controller_limit_test.dart` (νέο) · +S6, +S7 στο `unit_quantity_price_section_test` · +1 στο `app_messages_test` · +1 στο `stream_providers_test` (494 γρ.) |

Backups: `backups/*_before_fase3_b5e1_*`, `*_before_fase3_b5e2_*`,
`*_before_fase3_b5e3_*`.

## 4. Verification

`flutter test` **‹N›/‹N›** ✓ · `flutter analyze` **‹No issues›** ✓ · κανένα
.dart >500 γρ.

## 5. Ανοιχτά (δεν υλοποιήθηκαν σε αυτό το Βήμα)

- **Επιβεβαίωση εξόδου με μη αποθηκευμένες γραμμές** (§2.2 «Ημιτελής
  καταχώρηση»): το `AppMessages.exitUnsavedConfirm` υπάρχει χωρίς καταναλωτή·
  δεν υπάρχει `ConfirmDialog` (§2.4) ούτε `PopScope`. Δεν ανήκει σε κανένα
  υποβήμα του Βήματος 5 — να προγραμματιστεί ρητά.
- **Validation στο save** (`receipt_validator`, `maxReceiptLines` κ.λπ.) →
  Βήμα 6.

## 6. Επόμενο

Φάση 3, Βήμα 6: Validation μέσω SPoT validators
(`domain/validators/receipt_validator.dart`, §2.2).