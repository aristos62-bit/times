# 007 — Session 9 (11/09/2026) — Phase 3 (Receipt Feature), Steps 1–2

> 1 κεφάλαιο ανά φάση (κανόνας AGENTS.md #10). Το παρόν αφορά τη **Phase 3 —
> Βήματα 1–2 (Input models SPoT + ReceiptDao)**. Η Phase 3 θα συνεχίσει στο ίδιο
> αρχείο μέχρι να ξεπεραστούν οι 500 γραμμές (τότε νέο αρχείο).

## Part A — Βήμα 1: Input models SPoT `receipt_input.dart`

### Απόφαση (εγκεκριμένη)
- **Route A-Συνεπές** (από σχεδιασμό Phase 3): drift DataClasses = SPoT entities·
  ΧΩΡΙΣ domain entities/DTO/datasource/usecases. Δημιουργούνται μόνο: input models +
  ReceiptDao + abstract/impl repository + BLoC + UI.
- Τα 4 classes (`ReceiptInput`, `ReceiptItemInput`, `PaymentInput`,
  `ReceiptItemUpdate`) ορίζονται ΜΟΝΟ στο §5.1.3 DESIGN.md — SPoT (απαγόρευση
  δεύτερου ορισμού αλλού).

### Υλοποίηση
- **Νέο αρχείο:** `lib/features/receipt/domain/models/receipt_input.dart` (~102 γρ.,
  <500 όριο). Pure immutable data carriers (BLoC → DAO → DB), χωρίς I/O,
  validation, `==`/`hashCode`/`copyWith`.
- `ReceiptItemInput.vatRate` default = **`AppConstants.defaultVatRate`** (SPoT §1.x,
  ΟΧΙ literal 24.0 — μαζί με το DESIGN το ευθυγραμμίστηκε: `vatRate = 24.0` →
  `vatRate = AppConstants.defaultVatRate` στο DESIGN §5.1.3).
- `ReceiptInput.items` = **required** (χωρίς default), `payments` default
  `const []`, nullables χωρίς default.
- Τα columns `receipt_items.notes` & `payments.notes` **ΔΕΝ** εκτίθενται στα input
  models (καταγεγραμμένη απόφαση).
- Add import `../../../../core/constants/app_constants.dart`.

### Tests
- **Νέο αρχείο:** `test/unit/features/receipt/domain/models/receipt_input_test.dart`
  (12 tests). Groups: `ReceiptItemInput` (defaults AppConstants, custom χωρίς
  literals, const canonicalization), `ReceiptInput` (1:1 fields, defaults,
  `const []`), `PaymentInput`, `ReceiptItemUpdate` (+ const canonicalization),
  «Συμβόλαιο pure carrier» (negative/NaN χωρίς exception).
- **Όχι literal 24.0** στα asserts — μόνο σύγκριση με `AppConstants.defaultVatRate`.

### Επαλήθευση
- `flutter analyze` → **0 issues**.
- `flutter test` (πλήρες suite) → **257/257** (245 + 12 νέα).

### Αρχιτεκτονικό σημείωμα
- `lib/core/utils/validators.dart:165` placeholder `ReceiptItemInput` ΜΕΝΕΙ άθικτο
  μέχρι το Βήμα 5 (αντικατάσταση = ξεχωριστή έγκριση). Κανένα αρχείο δεν έχει
  import και από τα δύο (δεν υπάρχει collision τώρα).
- `lib/core/database/tables/receipt_items.dart:16` υπάρχει προϋπάρχον hardcoded
  `Constant(24.0)` — **εκτός εμβέλειας Βήματος 1**· προαιρετική μελλοντική
  ευθυγράμμιση με `const Constant(AppConstants.defaultVatRate)` (θα προταθεί στο
  Βήμα 2 — ReceiptDao).

### DESIGN.md sync
- §5.1.3: σημείωση υλοποίησης + default `AppConstants.defaultVatRate`.
- §2 tree: `receipt/domain/models/receipt_input.dart` ✅.
- §8.1: γραμμή `ReceiptInput models` (12 tests).
- §9 Phase 3: Σημείωση προόδου (Step 1 ✅ + σειρά επόμενων βημάτων) + checklist.
- Footer date → 2026-09-11.
- Backups: `backups/DESIGN_20260911_102924.md`, `backups/oldsessions_20260911_102924.md`,
  `backups/oldsessions_006_20260911_102924.md`.

## Επόμενα (Phase 3)
1. **Βήμα 4** — `ReceiptRepository` abstract+impl + εγγραφή στο
   `dependency_injection.dart` + tests.
2. **Βήμα 5** — αντικατάσταση placeholder στο `validators.dart` +
   `validators_test.dart` (χρειάζεται ξεχωριστή έγκριση· edits 2 αρχείων).
3. **Βήμα 6** — `ReceiptBloc`/Event/State + `bloc_test` (χρηση
   `DependencyInjection.get<ReceiptRepository>()`).
4. **Βήμα 7** — Presentation widgets/screens + widget tests.
5. **Βήμα 8** — sync DESIGN.md + oldsessions + backups.

---

## Part B — Βήμα 2: ReceiptDao `receipt_dao.dart` + codegen + tests

### Απόφαση (εγκεκριμένη — αρχική πρόταση + επανέλεγχος με πλήρη ανάγνωση αρχείων)
- Δ1(α): **counter-based αρίθμηση** μέσω `SettingDao` (SPoT) — ΟΧΙ απευθείας
  accessor user_settings από το ReceiptDao.
- Δ2(α): **stock delta** μέσω υπάρχουσας `ItemDao.increaseStock` (reuse).
- Δ4: `DoubleExtensions.approximates` για συγκρίσεις double (reuse).
- Δ3, Δ5–Δ7: όπως προτάθηκαν (πεδία απόδειξης / paymentMethod enum / notes exposure).
- Δ8: accessor `[Receipts, ReceiptItems, Payments, PriceHistory, Items, Categories]`
  (Items/Categories απαραίτητα για τα live aggregates §5.1.6) — **χωρίς UserSettings**.

### Υλοποίηση
- **Νέο αρχείο:** `lib/core/database/daos/receipt_dao.dart` (478 γρ. < 500).
  Αποκλίσεις από §4.3 (καταγεγραμμένες στο docstring):
  - `_refreshFinancials`: **ένα** write για totals+paid+remaining+status
    (αντί 2 βημάτων· αναγκαίο για σωστή ροή stream).
  - `watchAllReceipts` ordering: `receiptDate desc` + **tiebreak `id desc`**.
  - `updateReceiptItem`: param `itemUpdate` (όχι `update` — shadowing drift accessor).
  - Οι 3 fixes του §4.3: `Variable<T>()` (1), `DoUpdate(target:)` (2),
    timestamps `createdAt/updatedAt` στο finish (3).
- `createReceipt`: **transaction** receipt+items+payments+stock+price_history+
  bump counter (`settingDao.setSetting` στο ίδιο transaction).
- **Reuse:** `ItemDao.increaseStock`, `TagDao.removeAllTagsFromReceipt` (delete),
  `DoubleExtensions.approximates`, `AppConstants.defaultVatRate`.
- Barrel: `daos.dart` + `export 'receipt_dao.dart';`.
- Codegen: `dart run build_runner build` ✅ · **κανένα υπάρχον `.g.dart` δεν άλλαξε**.
- **Backups:** `backups/daos_20260911_111008.dart`, `backups/DESIGN_20260911_111008.md`,
  `backups/oldsessions_20260911_111008.md`, `backups/receipt_dao_test_20260911_151000.dart`.

### Tests (37 — χωρισμένα για το όριο των 500 γρ.)
- **CRUD:** `test/unit/core/database/daos/receipt_dao_test.dart` (33 tests, 413 γρ.).
- **Aggregates:** `test/unit/core/database/daos/receipt_dao_aggregates_test.dart`
  (4 tests, 76 γρ.).
- **Fixture:** `test/unit/core/database/daos/receipt_dao_test_fixture.dart`
  (82 γρ.) — κοινό setup (AppDatabase.test + SettingDao/ItemDao/TagDao +
  createReceipt helper). Το ενιαίο αρχείο ήταν 509 γρ. (>500) → split.
- Κάλυψη: watchAllReceipts (ordering/filter εύρος+supplier+status), getReceiptById,
  watchReceiptItems, getNextReceiptNumber, createReceipt (totals/vat/discount/
  status/stock/price_history/FK errors/μοναδικοί αριθμοί), updateReceiptItem
  (stock delta + paid→partial downgrade), deleteReceiptItem, deleteReceipt
  (cascade + stock restore + price_history διατηρείται), aggregates (count/
  byDateRange/byCategory/avg).

### Επαλήθευση
- `flutter analyze` → **0 issues**.
- `flutter test` (πλήρες suite) → **294/294** (257 + 37 νέα).

### Backlog (εκτός εμβέλειας Βήματος 2)
- `ItemDao.softDeleteItem` (~line 65): `Value(DateTime.now())` **χωρίς `.toUtc()`**
  — ασυνεπές με τον κανόνα αποθήκευσης timestamps. Διόρθωση σε μελλοντικό βήμα.
- `receipt_items.dart:16` hardcoded `Constant(24.0)` → προαιρετική ευθυγράμμιση
  με `const Constant(AppConstants.defaultVatRate)`.

### DESIGN.md sync
- §8.1: +2 γραμμές (`ReceiptDao CRUD` 33 tests, `ReceiptDao aggregates` 4 tests).
- §9 Phase 3: Σημείωση προόδου (Step 2 ✅, αποφάσεις Δ1α/Δ2α/Δ4, αποκλίσεις) + checklist
  (Steps 1–2 ✅).
- Footer date → 2026-09-11 (ήδη).