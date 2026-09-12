## 5.2 Repositories (Phase 2 Step 4 — Route A-Συνεπές, 10/09/2026)

> SPLIT (12/09/2026): συνέχεια του `design/07_features_layer.md` (κανόνας ≤500 γρ.).

**Απόκλιση:** Η πλήρης Clean-Architecture (entities/models/datasources/usecases/presentation
ανά feature) δημιουργείται μαζί με κάθε feature (Phase 3–6). Τώρα δημιουργήθηκαν
ΜΟΝΟ τα repositories (abstract + impl) για τα 4 features που έχουν DAO.
Δεν δημιουργήθηκαν domain entities — τα drift DataClasses (`Item`, `Category`,
`Supplier`, `Budget`) είναι τα current SPoT entities (immutable + `==`/`hashCode`).
`injection/dependency_injection.dart` υλοποιήθηκε πρόωρα στο Phase 2 Step 4.2 (απόκλιση
από §5.2 που προέβλεπε Phase 3). ReceiptRepository αναβάλλεται πλήρως στο Phase 3
(μαζί με ReceiptDao + §5.1.4/§5.1.5). **✅ Phase 3 Step 4 (11/09/2026):**
Έγινε το ReceiptRepository (abstract + impl + DI + 12 tests) → σύνολο
**5 repositories** εγγεγραμμένα στο DI:
`AppDatabase` → 7 DAOs → 5 repositories → `ThemeProvider`.

**ΟΧΙ UseCases/Entities για το Receipt (απόφαση 12/09/2026):** το `ReceiptBloc`
καλεί απευθείας το `ReceiptRepository` (Route A-Συνεπές). Κανένα usecase
(Create/Get/Update/Delete) δεν υλοποιήθηκε — το validation γίνεται στο BLoC μέσω
`Validators.validateReceipt` και οι ροές είναι reactive streams (δε χωράνε σε κλασικά
usecases). Θα προστεθούν ΜΟΝΟ όταν εμφανιστεί πραγματική cross-entity domain λογική.

**Abstract contracts** (`features/<f>/domain/repositories/<f>_repository.dart`):

| Feature | Methods (reactive / single-shot) |
|---|---|
| ItemRepository | `watchAll`, `watchByCategory`, `watchByBarcode`, `searchByName`, `watchLowStock`, `getById`, `create`, `update`, `softDelete`, `increaseStock` (10) |
| CategoryRepository | `watchAll`, `watchTree`, `watchWithChildrenRecursively`, `getById`, `create` ← throws `CategoryDuplicateNameException`, `update`, `softDelete` (7) |
| SupplierRepository | `watchAll`, `searchByName`, `getById`, `create`, `update`, `softDelete`, `getReceiptCount` (7) |
| BudgetRepository | `watchBudget`, `watchBudgetsForMonth`, `upsertBudget`, `watchDashboardSpending` (4) |
| ReceiptRepository | `watchAll`, `getById`, `watchItemsByReceiptId`, `create`, `updateItem`, `deleteItem`, `delete`, `getNextReceiptNumber`, `watchTotalByDateRange`, `watchTotalByCategory` (10) |

**Implementations** (`features/<f>/data/repositories/<f>_repository_impl.dart`):
Pure delegates — `const XxxRepositoryImpl(this._dao)`, κάθε μέθοδος 1:1 προώθηση.
`CategoryRepositoryImpl.create` προωθεί το `CategoryDuplicateNameException`
(category_dao.dart:128) χωρίς να το καταπνίγει.

**Special types** (ορίζονται στο `budget_dao.dart`, REUSE όχι αντίγραφα):
- `BudgetWithSpent` — `budget`, `spent`, `amount`, `categoryId`, `month`, `year` + computed
  `hasBudget`, `percentage`, `isOverBudget`, `remaining`
- `CategorySpending` — `categoryId`, `categoryName`, `color`, `icon`, `spent`

**Γιατί Route A-Συνεπές:** κανένας consumer (BLoC/screen/DI) δεν υπάρχει ακόμα,
οπότε τα repositories είναι pure wiring. Πλήρη δομή (entities/mappers/datasources)
έχει αξία μόνο μαζί με usecases/presentation — αποφυγή dead code + unnecessary
boilerplate. Αν στο μέλλον χρειαστεί domain `Receipt` entity, θα ζει μόνο εντός
`features/receipt/` με aliased imports (απόφαση Phase 3).
---

