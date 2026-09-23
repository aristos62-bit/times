# Φάση 4 — Βήμα 4: SettingsPage + category tree editor (23-09-2026)

> Κατάσταση: **Κλειστό**. Backup `backups/2026-09-23_fase4_b4_tree_editor/`
> (13 αρχεία πριν το βήμα).

---

## 1. Σκοπός

CRUD Κατηγοριών/Υποκατηγοριών με πύλη διαγραφής (DESIGN §2.3 · §4:464):
tree editor στο 2ο section της SettingsPage. Reuse ConfirmDialog
(isDestructive) + NameValidator + AppFeedback + έτοιμων providers Βήματος 3.

## 2. Υλοποίηση

- Repos (+ impl): `countItems` + `deleteWithContents` ×2 οντότητες (`_guard`
  → `DataLoadException`, pattern Βήματος 2). `deleteById` μένει αχρησιμοποίητο
  σκόπιμα — διαγραφή ΜΟΝΟ cascade μετά την πύλη.
- `settings_providers.dart` (+~50 γρ.): `inUseCountCategoryProvider` /
  `inUseCountSubCategoryProvider` (`FutureProvider.family<int,int>`, siblings
  των `canDelete*` — το bool δεν φτάνει για tooltip με πλήθος).
- SPoT: `AppStrings` +6 (`titleCategoriesSection/categoriesEmpty/editAction/
  deleteAction/refreshAction/saveAction`) · `AppMessages` +6 const (added/
  updated/deleted ×2) +3 dynamic (`itemsInUseTooltip` — διακριτό από
  `itemCountTooltip`, Α2-1 · 2 cascade confirms). `addNewCategory/
  addNewSubCategory` επαναχρησιμοποιήθηκαν ως labels κουμπιών (precedent
  `addNewItem` ως button). `AppErrors/AppConstants`: κανένα νέο.
- ΝΕΟ `state/settings_state.dart` (Freezed, `{isWorking}`) + `.freezed.dart`
  (build_runner · το `app_database.g.dart` noise επαναφέρθηκε).
- ΝΕΟ `controllers/category_management_controller.dart` (~230 γρ., plain
  `Notifier`): create/rename/delete ×2 + `getCategoryItemCount/
  getSubCategoryItemCount` (one-shot confirm) + `refreshGuards` (stale
  one-shot bools, IndexedStack). Dup-check in-memory (χωρίς UNIQUE στο
  schema)· rename με εξαίρεση εαυτού, self=no-op· πύλη defense-in-depth·
  validation/dup → record, DB → `DataLoadException` (DAO logged).
- ΝΕΟ `widgets/category_edit_dialog.dart` (~125 γρ., dumb + helper
  `showCategoryEditDialog` → `String?`).
- ΝΕΟ `widgets/category_tree_editor.dart` (~410 γρ.): `tree.when
  (skipLoadingOnReload)` → loading/error+Επανάληψη/empty/data·
  `ExpansionTile` + indented `ListTile` + `_deleteGate` (καθαρή→ενεργό·
  blocked→greyed+tooltip· error→tap-retry)· add buttons (`add_circle_outline`)
  + refresh· `_runOp` (op→feedback, pattern save button).
- `settings_page.dart` (60→76 γρ.): 2ο Card «Κατηγορίες» + docstring Α1
  (η βάση ανοίγει και από εδώ — στο launch ήδη ανοιχτή via PriceEntry).

## 3. Ευρήματα (εκτέλεση, όχι θεωρία)

- **Ε1 — Riverpod 3: `valueOrNull` ανύπαρκτο** (`AsyncValue` 3.4.3) → `.value`
  (precedent `price_entry_page`).
- **Ε2 — submit-through-UI rename κολλάει το FakeAsync** (tap save → async
  rename σε background isolate drift + snackbar + settle = hang· ούτε
  `--timeout 60s` δεν το σκότωσε, χρειάστηκε kill). Fix: το widget test
  ελέγχει wiring (open + prefill)· submit καλύπτεται από dialog + controller
  tests (σχόλιο ΣΗΜ. στο test).
- **Ε3 — `find.text('ΤΡΟΦΙΜΑ')` διπλό** (tile + prefill) → assert μέσω
  `tester.widget<TextField>().controller.text`.
- **Ε4 — app-level tests ήθελαν tree override**: `widget_test` + 3 pump sites
  `app_router_test` → `categoryTreeStreamProvider.overrideWith([])`
  (precedent Βήματος 7)· `settings_page_test` → DB override (inMemoryDb).
- **Ε5 — `flutter/foundation` `Category` vs drift `Category** (import
  conflict σε test) → αφαίρεση import.
- Μικρά: διπλό `});` + σπασμένη κεφαλίδα test (επισκευάστηκαν)· `Tail-Host`
  typo σε shell· `Timeout`/`grep` ανύπαρκτα σε PowerShell.

## 4. Tests (805 → 853, +48)

- SPoT gates (+6: strings 2 · messages 4 + `_allStrings/_allConstStrings`).
- ΝΕΟ `category_settings_passthrough_test` (8): count 0/N · cascade
  καθαρού/ανύπαρκτου→false · mapping → `DataLoadException`.
- ΝΕΟ `category_management_controller_test` (17): isWorking · create
  ok/κενό/dup · rename ok/noop/dup/άγνωστο · delete cascade/blocked
  (tooltip+rollback)/άγνωστο · sub ροή + scope-ανά-κατηγορία · counts ·
  refresh · DB→throw.
- ΝΕΟ `category_edit_dialog_test` (6) · tree editor (8: empty/nesting/
  confirm-Ακύρωση/blocked-tooltip/wiring/error+retry/mobile/dark).
- `settings_page_test` (+3: section κενό/δεδομένα/dark) · `widget_test` +
  `app_router_test` (tree overrides).
- `flutter analyze` No issues ✓ · `flutter test` **853/853** ✓ · κανένα
  αρχείο >500 γρ.

## 5. Συμβόλαια/ανοιχτά

- Refresh button για stale gates (PriceEntry-save). Rename δεν κάνει
  invalidate (δεν αλλάζει counts).
- Επόμενο: Βήμα 5 — BackupService + UI (μόνο με ρητό OK).
