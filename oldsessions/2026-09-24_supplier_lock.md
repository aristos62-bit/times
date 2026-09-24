# Κεφάλαιο 27 — Φάση 3 post-closure: κλείδωμα προμηθευτή μετά επιλογή (όπως είδος)

**Ημερομηνία έναρξης:** 24-09-2026 · **Κατάσταση:** Κλειστό

## Πρόβλημα (αίτημα χρήστη)

Μετά επιλογή προμηθευτή από τη λίστα αναζήτησης το πεδίο παρέμενε
επεξεργάσιμο (συμπεριφορά 22-09-2026: νέα πληκτρολόγηση → `onCleared` →
`setSupplier(null)`). Ζητήθηκε να κλειδώνει μέχρι την αποθήκευση, όπως
ακριβώς το είδος (ITEM_SELECTED: disabled field + banner + «Αλλαγή»).

## Απόφαση (εγκεκριμένη — τελική πρόταση 24-09)

Conditional render στον `ReceiptHeaderSection`: `supplier != null` →
locked banner (`ListTile` + «Αλλαγή», reuse SPoT `AppStrings.changeItem`)·
`null` → live search dropdown. Ξεκλείδωμα με «Αλλαγή» (`setSupplier(null)`
+ epoch) ή αυτόματα με καθαρισμό φόρμας (save/reset/exit-Ναι). Καμία αλλαγή
σε controller/state/providers/shared widget/save button.

## Επανέλεγχος reuse (τελικός)

- Reuse: `setSupplier(null)` (equality gate), `_supplierFieldEpoch` +
  `ref.listen` null-transition, `supplierSearchProvider`, `changeItem`,
  pattern banner είδους (`item_search_field:87-104`), `resetForm`/`saveReceipt`/
  exit-confirm/`SaveReceiptButton` disabled-OR.
- Απορρίφθηκαν: `enabled` param στο shared (θα άγγιζε 4 καταναλωτές) ·
  νέα `clearSupplier()` (διπλό του `setSupplier(null)`) · nested Card
  (ο header είναι ήδη Card → σκέτο `ListTile` όπως η γραμμή ημερομηνίας) ·
  αφαίρεση `onCleared` από το shared (το χρησιμοποιεί το unit section —
  αφαιρέθηκε μόνο το call-site προμηθευτή) · νέο string (reuse `changeItem`).
- `_clearedFromEdit` → dead code (το dropdown δεν υπάρχει όταν locked) →
  διαγράφηκε· το listen απλοποιήθηκε σε σκέτο epoch++.

## Αλλαγές

- **`lib/presentation/price_entry/widgets/receipt_header_section.dart`**
  (175→174 γρ.): watch `supplier`· conditional banner/dropdown· αφαίρεση
  `onCleared:` + `_clearedFromEdit`· doc header για lock.
- **`test/.../receipt_header_section_test.dart`**: το test typing-onCleared
  αντικαταστάθηκε με 3 lock tests (banner μετά επιλογή · «Αλλαγή» →
  αποεπιλογή + άδειο πεδίο + re-select edge · «+» κλειδώνει επίσης).
- **`test/.../price_entry_form_flow_test.dart`**: `pickItem` expects
  `changeItem` findsOneWidget → findsNWidgets(2) (supplier locked + είδος).
- **DESIGN.md §2.4.1**: η παράγραφος typing-αποεπιλογής (22-09) αντικαταστάθηκε
  με lock-banner (24-09).

## Tests

- Header: 19/19 (1 by-design fail πριν την αντικατάσταση → 0 μετά).
- Flow F1/F2: 2/2.
- Full suite: **855/855** ✓ (+2 net: −1 onCleared +3 lock).
- `flutter analyze` → **No issues** ✓ · κανένα `.dart` >500 γρ. ✓.

## Backup

- `backups/2026-09-24_supplier_lock/` — `receipt_header_section.dart` +
  `receipt_header_section_test.dart` + `price_entry_form_flow_test.dart` +
  `DESIGN.md` + `oldsessions.md` (πριν τις αλλαγές).
