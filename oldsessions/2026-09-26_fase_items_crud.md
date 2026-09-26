# Ρυθμίσεις: CRUD Ειδών (26-09-2026)

> Κατάσταση: **Κλειστό.**
> Αίτημα χρήστη: ενότητα «Είδη» με CRUD στις Ρυθμίσεις, πριν τις Κατηγορίες —
> με επαναχρησιμοποίηση υπαρχουσών λειτουργιών (SPoT/shared + λογική
> αναζήτησης απόδειξης), όχι διπλότυπα.

---

## 1. Αποφάσεις (Q&A, προτάθηκαν και εγκρίθηκαν)

- **Q1 search**: reuse `ItemSearchField` + `itemSearchControllerProvider` μέσω
  `ProviderScope.overrideWith(ItemSearchController.new)` fork (απομόνωση από
  τη φόρμα απόδειξης, μηδέν duplication).
- **Q2 edit**: πλήρες dialog (όνομα + dropdown υποκατηγορίας + dropdown
  προτεινόμενης μονάδας), όχι rename-only.
- **Q3 θέση**: section Ειδών ΠΡΙΝ τις Κατηγορίες.
- **Q4 delete**: πύλη με πλήθος γραμμών + greyed-out + tooltip (όχι
  error-after-tap).
- Πύλη μετρήσεων στο `ReceiptLineDao` (typed drift) → `ReceiptRepository`
  `countLinesByItemId` (συμμετρία με `countBySupplierId`), ΟΧΙ στο
  `ItemRepository`.
- Δημιουργία μέσω `NewItemFlowDialog` (μέσα στο forked search)· μόνο
  update/delete περνούν από τον νέο `ItemManagementController`.

## 2. Αλλαγές

- Data: `ReceiptLineDao.countByItemId` · `ReceiptRepository.countLinesByItemId`
  + impl · 4 test fakes ενημερώθηκαν.
- Providers: `canDeleteItemProvider` + `itemLinesCountProvider`
  (`settings_providers.dart`).
- Νέο `item_management_controller.dart` (update/delete/refreshGuards,
  καθάρισμα fork-επιλογής, invalidation sub+category guards).
- Νέο `item_edit_dialog.dart` (όνομα + Category/SubCategory/Unit
  `SearchableDropdownField`s, `ValueKey` υποκατηγορίας, `Value<int?>`
  semantics μονάδας)· **lookups ΠΡΙΝ το open** — το dialog μένει σύγχρονο,
  χωρίς async prefill.
- Νέο `item_list_editor.dart` (fork-scope wrapper + tiles/edit/DeleteGate/
  refresh).
- `settings_page.dart`: Card+ExpansionTile Ειδών πριν τις Κατηγορίες.
- SPoT: `AppStrings.titleItemsSection/itemsEmpty` ·
  `AppMessages.itemUpdated/itemDeleted/deleteItemConfirm/itemLinesTooltip`.
- `settings_page_test.dart` «κλειστά by default»: 4→5 sections (αναμενόμενο
  side effect, ενημερώθηκε).

## 3. Κρίσιμο εύρημα — `return future` flattening (test hang)

- Το helper `openDialog` επέστρεφε το dialog future από `async` συνάρτηση:
  σε `async` το `return future` το **υιοθετεί** (ισοδυναμεί με await).
  Τα tests prefill/dark δεν κλείνουν ποτέ το dialog → `await openDialog`
  περίμενε για πάντα (idle CPU, κανένα timeout δεν το έπιανε).
- Συμπτώματα που μπέρδεψαν: probes με πανομοιότυπη ροή περνούσαν (κανένα
  δεν επέστρεφε το future)· zombie `flutter_tester` + pipe-kill (`| Select
  -First`) ρύπαιναν τα runs· στο full suite φάνηκαν 4 «did not complete».
- Fix (test-only): wrapper-record `return (dialog: future);` — 4/4 σε 3''.
  Μάθημα: ποτέ `return` pending future από async helper (ίδια οικογένεια με
  το `.future` hang του κεφ. 9/row #25).

## 4. Tests

- Νέα: `item_edit_dialog_test` (4) · `item_list_editor_test` ·
  `item_management_controller_test` · `item_guard_providers_test`
  (listen+Completer, όχι `.future`+throwsA) · `receipt_line_count_test` (2) ·
  SPoT strings/messages · `receipt_totals_test`.
- Σουίτα **1167/1167** ✓ (+26 από 1141) · `flutter analyze` **No issues** ✓
  (2 warnings διορθώθηκαν: unused import dialog + unused `unitId` seed).

## 5. Docs

- DESIGN.md §2.3:321 scope (αρχιτεκτονική αλλαγή: «χωρίς νέο UI ειδών» →
  τώρα περιλαμβάνει Είδη)· τίποτα άλλο.
- Backups: `backups/2026-09-26_fase_items_crud/` + `settings_page_test.bak`
  + `item_edit_dialog_test.bak` + warnfix `.bak` ×2.
