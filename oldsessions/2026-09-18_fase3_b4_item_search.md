# Φάση 3 — Βήμα 4: Item search + "+" ροή δημιουργίας Είδους

> Ημερομηνία: 18-09-2026 · Κατάσταση: Κλειστό
> Το πεδίο Είδους στην PriceEntryPage αποκτά live αναζήτηση — inline
> panel (όχι dropdown) με «+» που ανοίγει το 3-βηματικό dialog
> (Κατηγορία → Υποκατηγορία → Είδος). Το dialog χρησιμοποιεί το κοινό
> `SearchableDropdownField` (Βήμα 3) για τις δύο πρώτες λίστες με
> in-memory φιλτράρισμα (families over repository streams).

---

## 1. Πεδίο & εγκεκριμένες αποφάσεις

DESIGN §4 Φάση 3 Βήμα 4 (item search/autocomplete + «+» popup ροή) και
§2.4 Πίνακας 2.4.1 — **«Συγχώνευση Α»**: το είδος έχει **δικό του inline
widget** (`item_search_field.dart`), όχι `SearchableDropdownField`. Οι
λίστες Κατηγορίας/Υποκατηγορίας ΜΕΣΑ στο dialog κάνουν **in-memory
φιλτράρισμα over ήδη-φορτωμένα repository streams** (§3) — κανένα νέο
DB query.

### 1.1 Αποφάσεις (εγκεκριμένες πριν την υλοποίηση)

1. **Search = `ItemSearchController` (AsyncNotifier)** — non-autoDispose:
   το IndexedStack κρατά ζωντανή τη σελίδα σε αλλαγή tab (§2.2:221).
2. **build() = idle, ΚΑΝΕΝΑ repo read** → η βάση δεν ανοίγει όσο κανείς
   δεν πληκτρολογεί (§2.0.1).
3. **Γραμμικά βήματα dialog, χωρίς «πίσω»**: Κατηγορία πάντα → Υποκατηγορία
   όταν οριστεί Κατηγορία → Όνομα όταν οριστεί Υποκατηγορία.
4. **Soft duplication** μέσω `NameValidator.isDuplicate` (exact-normalized,
   §2.0.4): Κατηγορία/Υποκατηγορία in-memory (`watchAll`/`watchByCategoryId`
   `.first`), Είδος exact `getByNormalizedName`.
5. **Snackbar ΠΟΤΕ μέσα στο dialog** (ScaffoldMessenger caveat) — ο καλών
   (item_search_field) δείχνει `itemAdded`/`itemExists` μετά το pop.

### 1.2 Σημείωση απόκλισης (αναφέρθηκε στον χρήστη, εγκρίθηκε)

Το `showDialog<NewItemDialogResult>` επιστρέφει **sealed result** αντί για
`Item`: `NewItemDialogCreated(item, created)` / `NewItemDialogCancelled` /
`NewItemDialogFailed`. Λόγος: ο καλών πρέπει να ξεχωρίζει «δημιουργήθηκε»
από «υπήρχε ήδη» (snackbar), «ακύρωση» από «dismiss» (αδράνεια) και
«DB σφάλμα» (δείχνει ο ίδιος `loadDataFailed`).

## 2. Αρχεία υλοποίησης

| Αρχείο | Σημειώσεις |
|---|---|
| `presentation/price_entry/state/item_search_state.dart` (νέο) | Freezed `ItemSearchState` — `query` · `status` (idle/found/notFound/searching) · `results` · `selectedItem` · `errorOccurred` |
| `presentation/price_entry/controllers/item_search_controller.dart` (νέο, <500 γρ.) | `AsyncNotifier` · build→idle (χωρίς repo reads) · `onQueryChanged`: trim + gating `searchMinChars` + ακύρωση debounce + token race-guard · `_search`: normalize → `.first` → found/notFound/error(retry) · `selectItem`/`clearSelection` (equality gate κατά id) · `createCategory`/`createSubCategory`/`createItem` (record `{entity, created}`) · **`ref.mounted` guards μετά τα async gaps** (fix 2 κατωτέρω) |
| `presentation/price_entry/widgets/item_search_field.dart` (νέο, <500 γρ.) | Inline panel: TextField (label fieldItemName) + status-driven panel (idle/searching/found ListView/notFound + «+»/error + retry) + banner επιλογής με «Αλλαγή» · κλείνει dialog → `AppFeedback` snackbar |
| `presentation/price_entry/widgets/new_item_flow_dialog.dart` (νέο, <500 γρ.) | AlertDialog maxWidth 440 · SearchableDropdownField<Category> (prefixIcon `category_outlined`) → SearchableDropdownField<SubCategory> (`folder_outlined`) → TextField Όνομα (maxLength 100) · «Ακύρωση»→`Cancelled` · «Προσθήκη» disabled όσο `_subCategory==null \|\| !_nameValid \|\| _isSaving` |
| `data/providers/stream_providers.dart` (update) | +`categorySearchProvider` family · +`subCategorySearchProvider` family `({categoryId, query})` — in-memory filter, κενό query → `Stream.value([])` (**fix 1** κατωτέρω) |
| `presentation/price_entry/price_entry_page.dart` (update) | +`ItemSearchField()` πάνω από το placeholder · placeholder moved κάτω |
| `presentation/shared/searchable_dropdown_field.dart` (update) | +`prefixIcon` / `resultLeadingIcon` (defaults store/business_outlined) |
| `domain/validators/name_validator.dart` (νέο Βήμα 4) | `validate` (κενό→nameRequired, >maxItemNameLength→nameTooLong) · `isDuplicate` (exact-normalized) — String? contract, no exceptions |
| `core/constants/app_strings.dart` (update) | +`fieldItemName` · `itemSearchHint` · `addNewItem` · `itemNotFound` (AppMessages, dynamic) · `newItemSave` · `newItemNextStep` (=«Επόμενο», προστέθηκε με gating test — τελικά **χωρίς χρήση**: τα βήματα προχωρούν αυτόματα) |
| `core/constants/app_messages.dart` (update) | +`itemAdded` (Ο … προστέθηκε) · `itemExists` (… υπάρχει ήδη) · `itemNotFound(query)` |
| `core/constants/app_errors.dart` (update) | +`nameRequired` · `nameTooLong` |

## 3. Core ευρήματα & fixes

### 3.1 `Stream.empty()` ΔΕΝ εκπέμπει value → loading για πάντα

Τα search families επέστρεφαν `const Stream.empty()` στο κενό query —
το `StreamProvider` μένει σε `AsyncLoading` επ' αόριστον (κανένα value
δεν εκπέμπεται ποτέ) → τα tests «κενό query → άμεσα []» έπεφταν με
timeout. Fix (lib): `Stream.value(const [])` — εκπέμπει άμεσα το κενό
χωρίς DB access, συνεπές με το contract του provider.

### 3.2 `ref.mounted` after async gaps στο AsyncNotifier

Το retry test αποκάλυψε `Cannot use the Ref after it has been disposed`
όταν ένα in-flight `_search` ολοκλήρωνε μετά το dispose του provider
(Riverpod error μάλιστα προτείνει: *«check ref.mounted after async gaps»*).
Fix (lib): guards `if (!ref.mounted) return;` πριν κάθε `_apply` στο
`_search` (τόσο στο data path, όσο και στο catch).

### 3.3 Test-side fixes (δικά μου σφάλματα, αναφέρθηκαν στον χρήστη)

1. **`waitForStatus` helper** δεν έπιανε κενό-query: αν το state είναι ήδη
   idle, το equality-gate του Riverpod δεν επανεκπέμπει — κανένα event δεν
   ερχόταν → timeout. Fix: check **τρέχον value πριν το listen**.
2. **`createSubCategory` dup test** έγραφε `'γαλακτ'` (πρόθεμα) ενώ ο
   `isDuplicate` είναι exact-normalized → περνούσε ως νέο. Fix: `'ΓΑΛΑΚΤΟΚΟΜΙΚΑ'`.
3. **Retry test predicate** `searching \|\| found` — το `searching` έρχεται
   πρώτο με κενά results → `expect(results, isNotEmpty)` fail. Fix: predicate
   μόνο `found` (ολοκληρωμένη αναζήτηση).
4. **Cancel test dialog** περίμενε `null` στο pop — το dialog κάνει
   `pop(NewItemDialogCancelled)` (null μόνο σε dismiss/barrier). Fix:
   `isA<NewItemDialogCancelled>()`.

## 4. Testing

**Suite: 485/485** ✓ (+75 από 410) · `flutter analyze` **No issues** ✓ ·
μείωση σε 0 flakes: widget tests χρησιμοποιούν in-memory DB + `runAsync`
settle (πραγματικά isolates, όχι fake) · κανένα αρχείο > 500 γραμμών ·
μηδέν νέα πακέτα.

Προσθήκες tests: `item_search_field_test` (9) · `new_item_flow_dialog_test`
(9) · `item_search_controller_test` (22) · `name_validator_test` (9) ·
stream_providers (+5 families) · searchable_dropdown_field icons (+2) ·
price_entry_page (item search παρόν) · app_strings/messages/errors (SPoT).

## 5. Backups

- `backups/*_before_fase3_b4_20260918_122314.dart` (13 αρχεία) — στιγμιότυπο
  πριν τη δέσμευση υλοποίησης.
- `backups/*_before_fase3_b4_fix2_20260918_133003.dart` — πριν τα fixes
  stream_providers + item_search_controller_test.
- `backups/*_before_fase3_b4_fix3_20260918_133843.dart` — πριν τα
  `ref.mounted` guards + retry test fix.

## 6. Σημείωση (μη-αρχιτεκτονική τεκμηρίωση)

Το SPoT `AppStrings.newItemNextStep` προστέθηκε μαζί με gating test, όμως
το dialog αποφάσισε να προχωρά αυτόματα μεταξύ βημάτων — άρα το string
μένει αχρησιμοποίητο στο UI. Δεν είναι blocker (SPoT dead-string, δεν το
πιάνει ο analyzer) — απόφαση χρήστη αργότερα για αφαίρεση ή χρήση.

## 7. Επόμενο

- Φάση 3, Βήμα 5: Εισαγωγή γραμμών απόδειξης (items με μονάδες/ποσότητες),
  ανακεφαλαίωση. `SearchableDropdownField` για Units (§2.4).