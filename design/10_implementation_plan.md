## 9. Βήματα Υλοποίησης

### Phase 1: Project Setup (Ημέρα 1-2)

1. **Δημιουργία Flutter Project**
   ```bash
   flutter create --org com.expense_tracker expense_tracker
   cd expense_tracker
   ```

2. **Εγκατάσταση Dependencies (Drift)**
   ```yaml
   # pubspec.yaml
   dependencies:
     flutter:
       sdk: flutter
     
     # Database (Drift)
     drift: ^2.14.0
     sqlite3_flutter_libs: ^0.5.0
     path_provider: ^2.1.0
     path: ^1.8.0
     
     # State Management
     flutter_bloc: ^8.1.0
     bloc: ^8.1.0
     
     # Navigation
     go_router: ^13.0.0
     
     # UI Components
     flutter_svg: ^2.0.9
     google_fonts: ^6.1.0
     
     # Charts
     fl_chart: ^0.66.0
     
     # Export
     pdf: ^3.10.4
     printing: ^5.11.1
     csv: ^5.1.0
     
     # Backup & Restore
     archive: ^3.4.0
     
     # Camera & Image
     image_picker: ^1.0.4
     
     # Barcode
     barcode_scan2: ^4.2.5
     
     # Security
     local_auth: ^2.1.7
     
     # Utils
     intl: ^0.19.0
     uuid: ^4.2.1
     collection: ^1.18.0
     equatable: ^2.0.5
   
   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^3.0.1
     drift_dev: ^2.14.0
     build_runner: ^2.4.6
     bloc_test: ^9.1.0
     mocktail: ^1.0.0
   ```

3. **Δημιουργία Δομής Φακέλων**
   - core/
   - features/
   - injection/

4. **Υλοποίηση Core SPOs**
   - constants
   - utils (formatters, validators)
   - theme
   - widgets (responsive_layout, auto_suggest_field)

5. **Εκτέλεση Drift Code Generation**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

### Phase 2: Database Layer (Ημέρα 3-5)

1. **Drift Tables**
   - Όλοι οι πίνακες (Categories, Suppliers, Items, Receipts, κλπ)
   - Indexes (μέσω Drift annotations)
   - Foreign Keys

2. **AppDatabase Class**
   - Initialization
   - Migrations
   - Seed data

3. **DAOs (Data Access Objects)**

   Υλοποιήθηκαν στο Phase 2 Step 3:
   - SettingDao (reactive theme/settings) — `lib/core/database/daos/setting_dao.dart`
   - CategoryDao (reactive queries + recursive CTE) — `category_dao.dart`
   - SupplierDao (reactive + search + receipt count) — `supplier_dao.dart`
   - ItemDao (reactive + low-stock + increaseStock) — `item_dao.dart`
   - TagDao (tags + receipt_tags junction) — `tag_dao.dart`
   - BudgetDao (live aggregate queries + dashboard top-8) — `budget_dao.dart`
   - Barrel export: `daos/daos.dart`

   **Review & διορθώσεις 2026-09-10 (Step 3.1):** το budget `_monthBounds`
   υπολόγιζε τα όρια με γυμνά strings ημερομηνίας αντί UTC ISO — απόδειξη της
   1ης του μήνα (τοπικό μεσονύχτι) έπεφτε στον προηγούμενο μήνα. Διορθώθηκε σε
   `DateTime(year, month, 1).toUtc().toIso8601String()`. Επίσης: `increaseStock`
   τώρα γράφει `updatedAt` σε UTC (`.toUtc()`), `setSetting` χρησιμοποιεί
   `DoUpdate(target: [key])` αντί `insertOrReplace` (σταθερό id), και
   `createCategory` κάνει app-level duplicate check (ρίζες με NULL parentId),
   πετώντας `CategoryDuplicateNameException`. Λεπτομέρειες στο §4.3 δεύτερο
   μπλοκ. Τests: +6 boundary/duplicate tests (σύνολο 206).

   Εκκρεμεί για το Phase 3 (Receipt Feature):
   - ~~ReceiptDao~~ — **μεταφέρθηκε στο Phase 3** (εξαρτάται από το feature/receipt).
     Σημείωση: το §4.3 snippet του ReceiptDao περιέχει 2 παλιά σφάλματα που
     διορθώνονται κατά την υλοποίηση του Phase 3:
     (1) χρησιμοποιεί `Expression.constant()` που δεν υπάρχει στο drift 2.34.x →
         αντικατάσταση με `Variable<T>(...)`,
     (2) `insertOnConflictUpdate` στοχεύει ΜΟΝΟ το PK — όπου χρειάζεται UNIQUE
         upsert απαιτείται `DoUpdate(... target: [...])`.
     (3) Στα quotes χρησιμοποιούνταν `PaymentInput`/`ReceiptItemUpdate` με
         `finish` χωρίς timestamp (`createdAt`/`updatedAt`) — θα διορθωθούν.

4. **Repositories**
   - ReceiptRepository — **αναβάλλεται στο Phase 3** (μαζί με ReceiptDao)
   - ItemRepository — ✅ Phase 2 Step 4 (abstract + impl, 30 tests)
   - CategoryRepository — ✅ Phase 2 Step 4 (abstract + impl, throws CategoryDuplicateNameException)
   - SupplierRepository — ✅ Phase 2 Step 4 (abstract + impl, getReceiptCount aggregate)
   - BudgetRepository — ✅ Phase 2 Step 4 (abstract + impl, BudgetWithSpent/CategorySpending reuse)

   **Review & διορθώσεις 2026-09-10 (Step 4.1):** υλοποιήθηκε Route A-Συνεπές —
   δημιουργήθηκαν ΜΟΝΟ abstract+impl (pure delegates) χωρίς domain entities/models/
   datasources/usecases. Τα drift DataClasses (`Item`, `Category`, `Supplier`, `Budget`)
   είναι τα current SPoT entities. Πλήρης Clean-Architecture (entities/models/datasources)
   ανά feature έρχεται με τα Phase 3–6.

   **DI Container (2026-09-10, Step 4.2):** `injection/dependency_injection.dart` — manual
   service locator (χωρίς get_it, δεν υπάρχει στο pubspec). Register→get→reset
   pattern. Εγγράφει: AppDatabase → 6 DAOs → 4 repositories → ThemeProvider.
   Guard: double configure → no-op. get πριν configure → StateError.
   reset() κλείνει DB + καθαρίζει singletons. 9 tests (configure/get/identity/
   override/reset/guard/duplicate). Χωρίς production consumers (ετοιμότητα Phase 3).

   **Theme provider fix (2026-09-10):** `ThemeProvider` συνδέθηκε με `SettingDao`
   (persistence στο user_settings table). `getThemeMode()` στο startup + reactive
   `watchThemeMode()` stream. Διαγράφηκε το stale WIP σχόλιο "SettingDao δεν υπάρχει".
   Tests ενημερώθηκαν σε AppDatabase.test() + SettingDao injection (9 tests).

### Phase 3: Receipt Feature (Ημέρα 6-10)

1. **Domain Layer**
   - Receipt Entity
   - ReceiptItem Entity
   - UseCases (Create, Get, Update, Delete)

2. **Data Layer**
   - ReceiptLocalDatasource
   - ReceiptRepositoryImpl
   - ReceiptModel (DTO)

3. **Presentation Layer**
   - ReceiptBloc
   - ReceiptEntryScreen
   - ReceiptListScreen
   - ReceiptDetailScreen
   - ReceiptForm Widget
   - ReceiptCard Widget

> **✅ Πρόοδος Phase 3 (11/09/2026):**
> **Step 1 — Input models SPoT (εκτελεσμένο):** `receipt_input.dart` + 12 tests → 257/257.
> **Step 2 — ReceiptDao (εκτελεσμένο):** `core/database/daos/receipt_dao.dart` (478 γρ. < 500)
> + codegen + 37 tests (CRUD 33 + aggregates 4) → 294/294. flutter analyze: 0 issues.
> Εγκριθείσες αποφάσεις: Δ1(α) counter-based receipt numbering μέσω SettingDao
> (όχι απευθείας user_settings από το ReceiptDao), Δ2(α) stock delta μέσω
> ItemDao.increaseStock, Δ4 DoubleExtensions.approximates. Καταγεγραμμένες αποκλίσεις:
> accessor1 = Items/Categories (χρειάζονται τα live aggregates §5.1.6) χωρίς UserSettings·
> `_refreshFinancials` = μοναδικό write totals+paid+remaining+status (αντί 2 βημάτων §4.3).
> **Step 4 — ReceiptRepository (εκτελεσμένο):** abstract `receipt_repository.dart`
> (52 γρ.) + impl `receipt_repository_impl.dart` (76 γρ., `const`) + 12 tests στο
> `receipt_repository_impl_test.dart` + DI registration (ReceiptDao με
> settingDao/itemDao/tagDao + ReceiptRepository) + DI test asserts → 306/306.
> **Step 5 — Validators placeholder (εκτελεσμένο):** αντικατάσταση placeholder
> `ReceiptItemInput` με SPoT import + per-item checks (quantity/unitPrice/itemId/
> vatRate/discount) με `isFinite`/`maxQuantity`/`maxPrice`/`maxDiscountPercent` +
> 3 νέα AppConstants + 3 νέα AppStrings + 14 edge tests → **321/321, analyze clean**.
> Σειρά εκτέλεσης βημάτων: 3) codegen + DAO tests ✅, 4) ReceiptRepository
> abstract+impl + DI ✅, 5) αντικατάσταση placeholder `validators.dart` ✅, 6) BLoC ✅,
> 7) presentation ✅, 8) sync .md.
> **Step 6 — ReceiptBloc (εκτελεσμένο, 11/09/2026):** `receipt_event.dart` (4 events
> χρήστη + 3 εσωτερικά bridge events, §5.1.7), `receipt_state.dart`, `receipt_bloc.dart`
> + 21 bloc tests (12 blocTest με πραγματικό DAO fixture + 8 plain reactive + 3 mocktail
> edge) → **342/342, analyze clean**. Κρίσιμες αποφάσεις: bridge pattern για τα reactive
> streams (emit μόνο εντός handler, bloc 9), `selectedReceipt` derive χωρίς getById (F3),
> LOCAL dates (F6), validateReceipt πριν create (F8). Λεπτομέρειες στο §5.1.7.
> **Step 7 — Presentation (εκτελεσμένο, 11/09/2026):** 4 widgets + 3 screens
> (BlocConsumer, callbacks για navigation — χωρίς Navigator.push στα screens) +
> `ReceiptMessageShown` bridge + 46 tests (widget 43 + bloc 3) → **388/388**.

### Phase 4: Item & Category Features (Ημέρα 11-15)

1. **Item Feature**
   - Domain, Data, Presentation layers
   - Search with fuzzy matching
   - Stock management

2. **Category Feature**
   - Domain, Data, Presentation layers
   - Tree structure (parent-child)
   - CRUD operations

### Phase 5: Supplier Feature (Ημέρα 16-18)

1. **Supplier Feature**
   - Domain, Data, Presentation layers
   - CRUD operations
   - Search functionality

### Phase 6: Budget Feature (Ημέρα 19-22)

1. **Budget Feature**
   - Domain, Data, Presentation layers
   - Monthly budgets per category
   - Spending tracking
   - Progress indicators

### Phase 7: Reports & Analytics (Ημέρα 23-27)

1. **Reports Feature**
   - Domain, Data, Presentation layers
   - Category breakdown chart
   - Price history chart
   - Summary statistics
   - PDF export
   - CSV export

### Phase 8: Dashboard (Ημέρα 28-30)

1. **Dashboard Screen**
   - Summary cards
   - Recent receipts
   - Budget progress
   - Quick actions

### Phase 9: Navigation & Polish (Ημέρα 31-33)

1. **Navigation**
   - Responsive navigation (mobile/tablet/desktop)
   - Routing with go_router

2. **Theme**
   - Light/Dark mode
   - System detection
   - Persistent preference

### Phase 10: Testing (Ημέρα 34-38)

1. **Unit Tests**
   - All utilities
   - All repositories
   - All use cases

2. **Widget Tests**
   - All custom widgets
   - All screens

3. **Integration Tests**
   - Critical user flows

### Phase 11: Polish & Deployment (Ημέρα 39-42)

1. **Performance Optimization**
   - Lazy loading
   - Caching
   - Database optimization

2. **Error Handling**
   - Global error handler
   - User-friendly error messages

3. **Deployment**
   - Android build
   - iOS build
   - Web build
---

