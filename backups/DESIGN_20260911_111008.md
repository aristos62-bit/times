# ExpenseTracker - Αναλυτικός Σχεδιασμός Υλοποίησης

## 📋 Πίνακας Περιεχομένων

1. [Αρχιτεκτονική Εφαρμογής](#1-αρχιτεκτονική-εφαρμογής)
2. [Δομή Φακέλων](#2-δομή-φακέλων)
3. [Core Layer (SPOs & Utilities)](#3-core-layer-spos--utilities)
4. [Database Layer (Drift)](#4-database-layer-drift)
5. [Features Layer](#5-features-layer)
6. [Responsive Design System](#6-responsive-design-system)
7. [Theme System (Dark/Light)](#7-theme-system-darklight)
8. [Testing Strategy](#8-testing-strategy)
9. [Βήματα Υλοποίησης](#9-βήματα-υλοποίησης)

---

## 1. Αρχιτεκτονική Εφαρμογής

### 1.1 Architecture Pattern: Clean Architecture + BLoC/Cubit

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
│  │ Screens │  │ Widgets │  │  BLoC   │  │ States  │       │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                           │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                    │
│  │Entities │  │UseCases │  │Repositories│                  │
│  │ (Models)│  │         │  │ (abstract) │                  │
│  └─────────┘  └─────────┘  └─────────┘                    │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐      │
│  │ DAOs    │  │  Drift  │  │Repositories│ │  Mappers│     │
│  │(Drift)  │  │  Tables │  │  (impl)   │  │         │     │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 State Management: flutter_bloc + Drift Streams

**Αιτιολογία:**
- Testable (εύκολο unit testing)
- Predictable state changes
- Separation of UI ↔ Business Logic
- Υποστήριξη complex state flows
- Drift `.watch()` streams δίνουν αυτόματη reactive UI ενημέρωση

### 1.3 Database: Drift (αντί sqflite/floor)

**Γιατί Drift:**
- **Type-safe** queries (compile-time errors αντί runtime)
- **Reactive** streams (αυτόματη ενημέρωση UI)
- **Better testing** (in-memory database)
- **Type-safe migrations**
- **No SQL triggers** - λογική σε Dart transactions (λύση reactivity issues)

### 1.4 Γλώσσα & Strings

**Κανόνας:** Η εφαρμογή είναι **αποκλειστικά στα Ελληνικά**. Όλα τα μηνύματα (validation errors, UI labels, success/error messages, dialogues) είναι στα ελληνικά.

- **Κεντρικό αρχείο strings:** `core/strings/app_strings.dart`
  - **SPoT** — ΜΟΝΟ αυτό το αρχείο περιέχει τα μηνύματα προς τον χρήστη
  - **Κανένα** string δεν εμφανίζεται inline σε screens/widgets/DAOs
  - Κάθε widget/screen κάνει import το `AppStrings` και διαβάζει το αντίστοιχο field
  - Αν χρειαστεί ποτέ μετάφραση σε άλλη γλώσσα, αλλάζει **μόνο** αυτό το αρχείο
  - Include: validation messages, button labels, screen titles, dialog text, error messages, empty state messages, snackbar messages

### 1.5 Debug Config & Logging

**Κανόνας:** Δεν χρησιμοποιούμε `print()` ή `debugPrint()` οπουδήποτε. Όλα τα logs γίνονται μέσω κεντρικού `DebugConfig` + `AppLogger`.

- **`core/debug/debug_config.dart`** — SPO: διαχείριση debug flags
  - `static const bool isDebug = kDebugMode` (αυτόματα true σε debug, false σε release)
  - Ομαδοποιημένα flags: `showDbLogs`, `showBlocLogs`, `showNetworkLogs`, `showPerformanceLogs`
  - Flags ρυθμίζονται **μόνο** εδώ (όχι scattered booleans)

- **`core/debug/app_logger.dart`** — SPO: κεντρικός logger
  - `AppLogger.db(msg)` — database operations (queries, inserts, migrations)
  - `AppLogger.bloc(msg)` — BLoC state changes, events
  - `AppLogger.network(msg)` — HTTP calls (αν υπάρξει)
  - `AppLogger.performance(msg)` — slow queries, rebuilds
  - `AppLogger.info(msg)` — general info
  - `AppLogger.error(msg, [stackTrace])` — errors
  - Κάθε log line έχει **prefix tag** (π.χ. `[DB]`, `[BLOC]`, `[NET]`)
  - Σε release mode τίποτε δεν τυπώνεται (αυτόματο)

---

## 2. Δομή Φακέλων

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_constants.dart          # SPO: App-wide constants
│   │   ├── database_constants.dart     # SPO: DB table/column names
│   │   └── asset_paths.dart            # SPO: Asset references
│   │
│   ├── strings/
│   │   └── app_strings.dart            # SPO: All user-facing strings (EL)
│   │
│   ├── debug/
│   │   ├── debug_config.dart           # SPO: Debug flags (DB, BLoC, Network, Performance)
│   │   └── app_logger.dart             # SPO: Centralized logger with group tags
│   │
│   ├── theme/
│   │   ├── app_theme.dart              # SPO: Theme definitions
│   │   ├── app_colors.dart             # SPO: Color palette
│   │   ├── app_text_styles.dart        # SPO: Typography
│   │   ├── app_dimensions.dart         # SPO: Spacing/sizing
│   │   └── theme_provider.dart         # SPO: Theme state (Drift-backed)
│   │
│   ├── utils/
│   │   ├── currency_formatter.dart     # SPO: Currency formatting
│   │   ├── date_formatter.dart         # SPO: Date formatting
│   │   ├── validators.dart             # SPO: Input validation
│   │   ├── extensions.dart             # SPO: Dart extensions
│   │   └── helpers.dart                # SPO: Helper functions
│   │
│   ├── widgets/
│   │   ├── responsive_layout.dart      # SPO: Responsive wrapper
│   │   ├── auto_suggest_field.dart     # SPO: Auto-complete widget
│   │   ├── loading_indicator.dart      # SPO: Loading states
│   │   ├── error_widget.dart           # SPO: Error display
│   │   ├── empty_state.dart            # SPO: Empty list states
│   │   └── confirm_dialog.dart         # SPO: Confirmation dialogs
│   │
│   └── database/
│       ├── app_database.dart            # SPO: Main Drift database class
│       ├── app_database.g.dart          # Generated by build_runner
│       ├── daos/
│       │   ├── daos.dart                 # Barrel export όλων των DAOs
│       │   ├── receipt_dao.dart         # SPO: Receipt Data Access Object (Phase 3)
│       │   ├── item_dao.dart            # SPO: Item Data Access Object
│       │   ├── category_dao.dart        # SPO: Category Data Access Object
│       │   ├── supplier_dao.dart        # SPO: Supplier Data Access Object
│       │   ├── budget_dao.dart          # SPO: Budget Data Access Object
│       │   ├── tag_dao.dart             # SPO: Tag Data Access Object
│       │   └── setting_dao.dart         # SPO: User settings Data Access Object
│       ├── migrations/
│       │   └── migration_test.dart      # SPO: Schema/data migration helpers
│       ├── backup/
│       │   └── backup_service.dart      # SPO: Backup & Restore service
│       └── tables/
│           ├── utc_date_time_converter.dart # SPoT: UTC DateTime TypeConverter
│           ├── categories.dart          # SPO: Categories table
│           ├── suppliers.dart           # SPO: Suppliers table
│           ├── items.dart               # SPO: Items table
│           ├── receipts.dart            # SPO: Receipts table
│           ├── receipt_items.dart       # SPO: Receipt items table
│           ├── payments.dart            # SPO: Payments table
│           ├── price_history.dart       # SPO: Price history table
│           ├── budgets.dart             # SPO: Budgets table
│           ├── tags.dart                # SPO: Tags table
│           ├── receipt_tags.dart        # SPO: Receipt tags table
│           └── user_settings.dart       # SPO: User settings table
│
├── features/
│   ├── receipt/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── receipt_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── receipt_model.dart
│   │   │   └── repositories/
│   │   │       └── receipt_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── receipt.dart
│   │   │   ├── models/
│   │   │   │   └── receipt_input.dart   # ✅ Phase 3 Step 1 (11/09/2026): SPoT input models (§5.1.3)
│   │   │   ├── repositories/
│   │   │   │   └── receipt_repository.dart (abstract)
│   │   │   └── usecases/
│   │   │       ├── create_receipt.dart
│   │   │       ├── get_receipts.dart
│   │   │       ├── update_receipt.dart
│   │   │       └── delete_receipt.dart
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── receipt_bloc.dart
│   │       │   ├── receipt_event.dart
│   │       │   └── receipt_state.dart
│   │       ├── screens/
│   │       │   ├── receipt_entry_screen.dart
│   │       │   ├── receipt_list_screen.dart
│   │       │   └── receipt_detail_screen.dart
│   │       └── widgets/
│   │           ├── receipt_form.dart
│   │           ├── receipt_card.dart
│   │           └── receipt_item_list.dart
│   │
│   ├── item/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── item_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── item_model.dart
│   │   │   └── repositories/
│   │   │       └── item_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── item.dart
│   │   │   ├── repositories/
│   │   │   │   └── item_repository.dart (abstract)
│   │   │   └── usecases/
│   │   │       ├── create_item.dart
│   │   │       ├── get_items.dart
│   │   │       ├── search_items.dart
│   │   │       └── update_stock.dart
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── item_bloc.dart
│   │       │   ├── item_event.dart
│   │       │   └── item_state.dart
│   │       ├── screens/
│   │       │   ├── item_list_screen.dart
│   │       │   └── item_form_screen.dart
│   │       └── widgets/
│   │           ├── item_card.dart
│   │           └── stock_indicator.dart
│   │
│   ├── category/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── category_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── category_model.dart
│   │   │   └── repositories/
│   │   │       └── category_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── category.dart
│   │   │   ├── repositories/
│   │   │   │   └── category_repository.dart (abstract)
│   │   │   └── usecases/
│   │   │       ├── create_category.dart
│   │   │       ├── get_categories.dart
│   │   │       └── get_category_tree.dart
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── category_bloc.dart
│   │       │   ├── category_event.dart
│   │       │   └── category_state.dart
│   │       ├── screens/
│   │       │   └── category_list_screen.dart
│   │       └── widgets/
│   │           ├── category_card.dart
│   │           └── category_tree.dart
│   │
│   ├── supplier/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── supplier_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── supplier_model.dart
│   │   │   └── repositories/
│   │   │       └── supplier_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── supplier.dart
│   │   │   ├── repositories/
│   │   │   │   └── supplier_repository.dart (abstract)
│   │   │   └── usecases/
│   │   │       ├── create_supplier.dart
│   │   │       ├── get_suppliers.dart
│   │   │       └── search_suppliers.dart
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── supplier_bloc.dart
│   │       │   ├── supplier_event.dart
│   │       │   └── supplier_state.dart
│   │       ├── screens/
│   │       │   ├── supplier_list_screen.dart
│   │       │   └── supplier_form_screen.dart
│   │       └── widgets/
│   │           └── supplier_card.dart
│   │
│   ├── budget/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── budget_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── budget_model.dart
│   │   │   └── repositories/
│   │   │       └── budget_repository_impl.dart
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── budget.dart
│   │   │   ├── repositories/
│   │   │   │   └── budget_repository.dart (abstract)
    │   │   │   └── usecases/
    │   │   │       ├── create_budget.dart
    │   │   │       ├── get_budgets.dart
    │   │   │       └── watch_budget_spending.dart
│   │   │
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── budget_bloc.dart
│   │       │   ├── budget_event.dart
│   │       │   └── budget_state.dart
│   │       ├── screens/
│   │       │   └── budget_screen.dart
│   │       └── widgets/
│   │           ├── budget_card.dart
│   │           └── budget_progress.dart
│   │
│   └── reports/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── report_local_datasource.dart
│       │   └── repositories/
│       │       └── report_repository_impl.dart
│       │
│       ├── domain/
│       │   ├── entities/
│       │   │   └── report.dart
│       │   ├── repositories/
│       │   │   └── report_repository.dart (abstract)
│       │   └── usecases/
│       │       ├── generate_category_report.dart
│       │       ├── generate_price_history.dart
│       │       └── export_report.dart
│       │
│       └── presentation/
│           ├── bloc/
│           │   ├── report_bloc.dart
│           │   ├── report_event.dart
│           │   └── report_state.dart
│           ├── screens/
│           │   └── reports_screen.dart
│           └── widgets/
│               ├── category_chart.dart
│               ├── price_history_chart.dart
│               └── summary_card.dart
│
│   ── Εκτελεσμένα (Phase 2 Step 4 — Route A-Συνεπές, 10/09/2026) ──
│   Τα παρακάτω αρχεία υλοποιήθηκαν (pure delegates στους DAOs):
│   ├── item/data/repositories/item_repository_impl.dart
│   ├── item/domain/repositories/item_repository.dart
│   ├── category/data/repositories/category_repository_impl.dart
│   ├── category/domain/repositories/category_repository.dart
│   ├── supplier/data/repositories/supplier_repository_impl.dart
│   ├── supplier/domain/repositories/supplier_repository.dart
│   ├── budget/data/repositories/budget_repository_impl.dart
│   └── budget/domain/repositories/budget_repository.dart
│
│   Απόκλιση: δημιουργήθηκαν ΜΟΝΟ τα repositories (abstract+impl) —
│   όχι datasources/models/entities/usecases/presentation ανά feature.
│   Λόγος: drift DataClasses ως current SPoT entities, κανένας consumer
│   (BLoC/screen/DI) δεν υπάρχει ακόμα. Πλήρης Clean-Architecture δομή
│   ερχότανται μαζί με κάθε feature (Phase 3–6). ReceiptRepository
│   αναβάλλεται πλήρως στο Phase 3 (μαζί με ReceiptDao).
│
│
├── injection/
│   └── dependency_injection.dart       # SPO: Service locator (✅ Phase 2 Step 4.2)
│
└── test/
    ├── unit/
    │   ├── core/
    │   │   ├── utils/
    │   │   │   ├── currency_formatter_test.dart
    │   │   │   ├── date_formatter_test.dart
    │   │   │   └── validators_test.dart
    │   │   └── database/
    │   │       ├── app_database_test.dart
    │   │       └── daos/
    │   │           ├── setting_dao_test.dart
    │   │           ├── category_dao_test.dart
    │   │           ├── supplier_dao_test.dart
    │   │           ├── item_dao_test.dart
    │   │           ├── tag_dao_test.dart
    │   │           ├── budget_dao_test.dart
    │   │           └── receipt_dao_test.dart  (Phase 3)
    │   ├── features/
    │   │   ├── receipt/
    │   │   │   ├── domain/
    │   │   │   │   └── usecases/
    │   │   │   │       └── create_receipt_test.dart
    │   │   │   └── data/
    │   │   │       └── repositories/
    │   │   │           └── receipt_repository_test.dart
    │   │   ├── item/
    │   │   │   └── domain/
    │   │   │       └── usecases/
    │   │   │           └── search_items_test.dart
    │   │   └── budget/
    │   │       ├── domain/
    │   │       │   └── usecases/
    │   │       │       └── create_budget_test.dart
    │   │       └── data/
    │   │           └── dao/
    │   │               └── budget_dao_test.dart
    │   └── features/
    │       └── ...
    │
    ├── widget/
    │   ├── core/
    │   │   ├── widgets/
    │   │   │   ├── responsive_layout_test.dart
    │   │   │   ├── auto_suggest_field_test.dart
    │   │   │   └── loading_indicator_test.dart
    │   │   └── theme/
    │   │       └── app_theme_test.dart
    │   └── features/
    │       ├── receipt/
    │       │   └── presentation/
    │       │       └── widgets/
    │       │           └── receipt_form_test.dart
    │       └── ...
    │
    └── integration/
        ├── receipt_entry_flow_test.dart
        ├── budget_tracking_flow_test.dart
        └── report_generation_flow_test.dart
```

---

## 3. Core Layer (SPOs & Utilities)

### 3.1 App Constants (`core/constants/app_constants.dart`)

```dart
/// SPO: App-wide constants - NO magic numbers/strings
class AppConstants {
  AppConstants._();
  
  // App Info
  static const String appName = 'Τιμές';
  static const String appVersion = '1.0.0';
  
  // Database
  static const String dbName = 'expense_tracker.db';
  static const int dbVersion = 1;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Debounce
  static const Duration searchDebounce = Duration(milliseconds: 300);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxSearchResults = 10;
  
  // VAT Rates (Greece)
  static const List<double> vatRates = [0.0, 6.0, 13.0, 24.0];
  static const double defaultVatRate = 24.0;
  
  // Payment Methods
  static const List<String> paymentMethods = [
    'Μετρητά',
    'Κάρτα',
    'Μεταφορά',
    'Επιταγή',
  ];
  
  // Units
  static const List<String> units = [
    'τεμ',
    'κιλό',
    'γραμμάρια',
    'λίτρα',
    'μέτρα',
    'συσκευασία',
  ];
}
```

### 3.3 App Strings (`core/strings/app_strings.dart`)

> **l10n-readiness:** Το AppStrings χρησιμοποιεί **μόνο static const String**.
> Αν χρειαστεί μετάφραση (multi-language), αντικαθίσταται εύκολα με
> `AppLocalizations` (flutter gen-l10n) χωρίς αλλαγή στα widgets.
> Για πλασματικές μεταβλητές (π.χ. "Απόδειξη #1234"), χρησιμοποιούμε
> string interpolation (`'Απόδειξη #$number'`) που παραμένει ίδιο με l10n.

```dart
// core/strings/app_strings.dart
/// SPO: Κεντρικός φάκελος μηνυμάτων εφαρμογής (Ελληνικά)
/// ΚΑΝΕΝΑ string δεν εμφανίζεται inline σε screens/widgets.
/// Κάθε widget κάνει import το AppStrings και διαβάζει το αντίστοιχο field.
/// l10n: προαιρετικά, το SPoT παραμένει σωστό και χωρίς αυτό.
class AppStrings {
  AppStrings._();
  
  // --- Screen Titles ---
  static const String homeTitle = 'Αρχική';
  static const String receiptsTitle = 'Αποδείξεις';
  static const String addReceiptTitle = 'Νέα Απόδειξη';
  static const String editReceiptTitle = 'Επεξεργασία Απόδειξης';
  static const String categoriesTitle = 'Κατηγορίες';
  static const String suppliersTitle = 'Προμηθευτές';
  static const String itemsTitle = 'Είδη';
  static const String budgetsTitle = 'Προϋπολογισμοί';
  static const String reportsTitle = 'Αναφορές';
  static const String settingsTitle = 'Ρυθμίσεις';
  
  // --- Validation Messages ---
  static const String requiredField = 'Υποχρεωτικό πεδίο';
  static const String invalidNumber = 'Μη έγκυρος αριθμός';
  static const String invalidVatNumber = 'Μη έγκυρος ΑΦΜ';
  static const String invalidIban = 'Μη έγκυρος IBAN';
  static const String invalidEmail = 'Μη έγκυρο email';
  static const String invalidPhone = 'Μη έγκυρο τηλέφωνο';
  static const String invalidDate = 'Μη έγκυρη ημερομηνία';
  static const String invalidTime = 'Μη έγκυρη ώρα';
  static const String priceMustBePositive = 'Η τιμή πρέπει να είναι θετική';
  static const String quantityMustBePositive = 'Η ποσότητα πρέπει να είναι θετική';
  static const String quantityExceedsStock = 'Η ποσότητα υπερβαίνει το απόθεμα';
  static const String categoryRequired = 'Επιλέξτε κατηγορία';
  static const String supplierRequired = 'Επιλέξτε προμηθευτή';
  static const String receiptDateRequired = 'Επιλέξτε ημερομηνία';
  
  // --- Button Labels ---
  static const String save = 'Αποθήκευση';
  static const String cancel = 'Ακύρωση';
  static const String delete = 'Διαγραφή';
  static const String edit = 'Επεξεργασία';
  static const String add = 'Προσθήκη';
  static const String confirm = 'Επιβεβαίωση';
  static const String back = 'Πίσω';
  static const String next = 'Επόμενο';
  static const String search = 'Αναζήτηση';
  static const String filter = 'Φίλτρο';
  static const String clear = 'Καθαρισμός';
  
  // --- Dialog Messages ---
  static const String deleteConfirmTitle = 'Διαγραφή;';
  static const String deleteConfirmMessage = 'Είστε σίγουροι ότι θέλετε να διαγράψετε αυτό το στοιχείο; Αυτή η ενέργεια δεν μπορεί να αναιρεθεί.';
  static const String unsavedChangesTitle = 'Μη αποθηκευμένες αλλαγές';
  static const String unsavedChangesMessage = 'Υπάρχουν μη αποθηκευμένες αλλαγές. Θέλετε να τις απορρίψετε;';
  
  // --- Success Messages ---
  static const String savedSuccessfully = 'Αποθηκεύτηκε επιτυχώς';
  static const String deletedSuccessfully = 'Διαγράφηκε επιτυχώς';
  static const String receiptAdded = 'Η απόδειξη καταχωρήθηκε επιτυχώς';
  static const String receiptUpdated = 'Η απόδειξη ενημερώθηκε επιτυχώς';
  static const String receiptDeleted = 'Η απόδειξη διαγράφηκε επιτυχώς';
  
  // --- Error Messages ---
  static const String genericError = 'Κάτι πήγε στραβά. Προσπαθήστε ξανά.';
  static const String databaseError = 'Σφάλμα βάσης δεδομένων';
  static const String notFound = 'Δεν βρέθηκε';
  static const String noReceipts = 'Δεν υπάρχουν αποδείξεις';
  static const String noItems = 'Δεν υπάρχουν είδη';
  static const String noCategories = 'Δεν υπάρχουν κατηγορίες';
  static const String noSuppliers = 'Δεν υπάρχουν προμηθευτές';
  static const String noBudgets = 'Δεν υπάρχουν budgets';
  static const String noDataForReport = 'Δεν υπάρχουν δεδομένα για αυτή την περίοδο';
  
  // --- Settings Labels ---
  static const String darkMode = 'Σκοτεινό θέμα';
  static const String lightMode = 'Φωτεινό θέμα';
  static const String systemDefault = 'Προεπιλογή συστήματος';
  static const String currency = 'Νόμισμα';
  static const String language = 'Γλώσσα';
  
  // --- Units ---
  static const String piece = 'τεμ';
  static const String kg = 'κιλά';
  static const String liter = 'λίτρα';
  static const String meter = 'μέτρα';
}
```

### 3.4 Debug Config (`core/debug/debug_config.dart`)

```dart
// core/debug/debug_config.dart
import 'package:flutter/foundation.dart';

/// SPO: Debug flags - Ρυθμίζονται ΜΟΝΟ εδώ
class DebugConfig {
  DebugConfig._();
  
  // --- Master Switch ---
  static const bool isDebug = kDebugMode;
  
  // --- Group Flags ---
  static const bool showDbLogs = isDebug && true;
  static const bool showBlocLogs = isDebug && true;
  static const bool showNetworkLogs = isDebug && true;
  static const bool showPerformanceLogs = isDebug && true;
  static const bool showNavigationLogs = isDebug && false;
  
  // --- Thresholds ---
  static const Duration slowQueryThreshold = Duration(milliseconds: 500);
  static const Duration slowBuildThreshold = Duration(milliseconds: 16); // >1 frame
}
```

### 3.5 App Logger (`core/debug/app_logger.dart`)

```dart
// core/debug/app_logger.dart
import 'package:flutter/foundation.dart';
import 'debug_config.dart';

/// SPoT: Κεντρικός logger — το DebugConfig ελέγχει αν τυπώνεται
/// 
/// Usage:
///   AppLogger.db('SELECT FROM receipts WHERE...');
///   AppLogger.bloc('ReceiptBloc: event=LoadReceipts');
///   AppLogger.network('GET /api/receipts - 200 OK');
///   AppLogger.performance('Slow query: 620ms - receipts join items');
///   AppLogger.error('Failed to insert', stackTrace);
class AppLogger {
  AppLogger._();
  
  static void db(String message) {
    if (!DebugConfig.showDbLogs) return;
    debugPrint('[DB] $message');
  }
  
  static void bloc(String message) {
    if (!DebugConfig.showBlocLogs) return;
    debugPrint('[BLOC] $message');
  }
  
  static void network(String message) {
    if (!DebugConfig.showNetworkLogs) return;
    debugPrint('[NET] $message');
  }
  
  static void performance(String message) {
    if (!DebugConfig.showPerformanceLogs) return;
    debugPrint('[PERF] $message');
  }
  
  static void navigation(String message) {
    if (!DebugConfig.showNavigationLogs) return;
    debugPrint('[NAV] $message');
  }
  
  static void info(String message) {
    if (!DebugConfig.isDebug) return;
    debugPrint('[INFO] $message');
  }
  
  static void error(String message, [StackTrace? stackTrace]) {
    if (!DebugConfig.isDebug) return;
    debugPrint('[ERROR] $message');
    if (stackTrace != null) {
      debugPrint('[ERROR] StackTrace: $stackTrace');
    }
  }
}
```

### 3.6 Currency Formatter (`core/utils/currency_formatter.dart`)

```dart
/// SPO: Currency formatting - single source of truth
class CurrencyFormatter {
  CurrencyFormatter._();
  
  static const String _defaultCurrency = '€';
  static const int _decimalPlaces = 2;
  
  /// Format: 1234.56 → "1.234,56€"
  static String format(double amount, {String currency = _defaultCurrency}) {
    final formatted = amount
        .toStringAsFixed(_decimalPlaces)
        .replaceAll('.', ',')
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return '$formatted$currency';
  }
  
  /// Format with sign: 1234.56 → "+1.234,56€", -50.00 → "-50,00€"
  static String formatWithSign(double amount, {String currency = _defaultCurrency}) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${format(amount, currency: currency)}';
  }
  
  /// Parse: "1.234,56€" → 1234.56
  static double parse(String formatted) {
    final cleaned = formatted
        .replaceAll(_defaultCurrency, '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.parse(cleaned);
  }
}
```

**Test File:** `test/unit/core/utils/currency_formatter_test.dart`

### 3.7 Date Formatter (`core/utils/date_formatter.dart`)

```dart
/// SPO: Date formatting - single source of truth
class DateFormatter {
  DateFormatter._();
  
  /// Short format: 15/01/2026
  static String formatShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }
  
  /// Full Greek format: 15 Ιανουαρίου 2026
  static String formatFull(DateTime date) {
    return '${date.day} ${_greekMonth(date.month)} ${date.year}';
  }
  
  /// Month/Year: Ιανουάριος 2026
  static String formatMonthYear(DateTime date) {
    return '${_greekMonthFull(date.month)} ${date.year}';
  }
  
  /// Time: 14:30
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Relative: "Σήμερα", "Χθες", "2 ημέρες πριν"
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;
    
    if (difference == 0) return 'Σήμερα';
    if (difference == 1) return 'Χθες';
    if (difference == 2) return 'Προχθές';
    if (difference < 7) return '$difference ημέρες πριν';
    return formatShort(date);
  }
  
  static String _greekMonth(int month) {
    const months = [
      'Ιανουαρίου', 'Φεβρουαρίου', 'Μαρτίου', 'Απριλίου',
      'Μαΐου', 'Ιουνίου', 'Ιουλίου', 'Αυγούστου',
      'Σεπτεμβρίου', 'Οκτωβρίου', 'Νοεμβρίου', 'Δεκεμβρίου'
    ];
    return months[month - 1];
  }
  
  static String _greekMonthFull(int month) {
    const months = [
      'Ιανουάριος', 'Φεβρουάριος', 'Μάρτιος', 'Απρίλιος',
      'Μάιος', 'Ιούνιος', 'Ιούλιος', 'Αύγουστος',
      'Σεπτέμβριος', 'Οκτώβριος', 'Νοέμβριος', 'Δεκέμβριος'
    ];
    return months[month - 1];
  }
}
```

**Test File:** `test/unit/core/utils/date_formatter_test.dart`

### 3.8 Validators (`core/utils/validators.dart`)

> **ΣΗΜΕΙΩΣΗ:** Τα μηνύματα validation εμφανίζονται inline για ευκολία ανάγνωσης.
> Στην πραγματική υλοποίηση, ΚΑΘΕ μήνυμα αντικαθίσταται με `AppStrings.xxx` (π.χ. `AppStrings.requiredField`).
>
> **Υλοποίηση Phase 1 (έγινε):** `AppStrings` παντού · `CurrencyFormatter.tryParse`
> για ποσότητα/τιμή/budget (ελληνικό κόμμα) · `approximates` για ΦΠΑ ·
> `trim().length` · EL μόνο ως prefix · `0030` · email TLD `{2,}` ·
> ανοχή +1 λεπτό στο μέλλον · `AppConstants.minReceiptDate`.

```dart
/// SPO: Input validation - single source of truth
/// Μηνύματα: core/strings/app_strings.dart (AppStrings)
import '../strings/app_strings.dart';

class Validators {
  Validators._();
  
  // Receipt Validators
  static String? validateReceiptDate(DateTime? date) {
    if (date == null) return AppStrings.receiptDateRequired;
    if (date.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return AppStrings.receiptDateInFuture;
    }
    if (date.isBefore(AppConstants.minReceiptDate)) return AppStrings.invalidDate;
    return null;
  }
  
  static String? validateSupplierId(int? supplierId) {
    if (supplierId == null || supplierId <= 0) return 'Επιλέξτε προμηθευτή';
    return null;
  }
  
  static String? validatePaymentMethod(String? method) {
    if (method == null || method.isEmpty) return 'Επιλέξτε τρόπο πληρωμής';
    return null;
  }
  
  // Item Validators
  static String? validateItemName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Εισάγετε όνομα είδους';
    if (name.length < 2) return 'Το όνομα πρέπει να έχει τουλάχιστον 2 χαρακτήρες';
    if (name.length > 100) return 'Το όνομα δεν μπορεί να υπερβαίνει τους 100 χαρακτήρες';
    return null;
  }
  
  static String? validateQuantity(String? quantity) {
    if (quantity == null || quantity.isEmpty) return 'Εισάγετε ποσότητα';
    final parsed = double.tryParse(quantity);
    if (parsed == null) return 'Μη έγκυρος αριθμός';
    if (parsed <= 0) return 'Η ποσότητα πρέπει να είναι θετικός αριθμός';
    if (parsed > 99999) return 'Η ποσότητα είναι πολύ μεγάλη';
    return null;
  }
  
  static String? validatePrice(String? price) {
    if (price == null || price.isEmpty) return 'Εισάγετε τιμή';
    final parsed = double.tryParse(price);
    if (parsed == null) return 'Μη έγκυρος αριθμός';
    if (parsed < 0) return 'Η τιμή δεν μπορεί να είναι αρνητική';
    if (parsed > 999999) return 'Η τιμή είναι πολύ μεγάλη';
    return null;
  }
  
  static String? validateVatRate(String? rate) {
    if (rate == null || rate.isEmpty) return 'Επιλέξτε συντελεστή ΦΠΑ';
    final parsed = double.tryParse(rate);
    if (parsed == null) return 'Μη έγκυρος συντελεστής';
    if (!AppConstants.vatRates.contains(parsed)) return 'Μη έγκυρος συντελεστής ΦΠΑ';
    return null;
  }
  
  // Category Validators
  static String? validateCategoryName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Εισάγετε όνομα κατηγορίας';
    if (name.length < 2) return 'Το όνομα πρέπει να έχει τουλάχιστον 2 χαρακτήρες';
    if (name.length > 50) return 'Το όνομα δεν μπορεί να υπερβαίνει τους 50 χαρακτήρες';
    return null;
  }
  
  // Supplier Validators
  static String? validateSupplierName(String? name) {
    if (name == null || name.trim().isEmpty) return 'Εισάγετε όνομα προμηθευτή';
    if (name.length < 2) return 'Το όνομα πρέπει να έχει τουλάχιστον 2 χαρακτήρες';
    return null;
  }
  
  static String? validateVatNumber(String? vat) {
    if (vat == null || vat.isEmpty) return null; // Optional
    final cleaned = vat.replaceAll('-', '').replaceAll(' ', '').replaceAll('EL', '').replaceAll('el', '');
    // Το ελληνικό ΑΦΜ είναι 9 ψηφία χωρίς πρόθεμα EL
    // (το EL χρησιμοποιείται μόνο σε ενδοκοινοτικό VIES format, δεν το αποθηκεύουμε)
    if (!RegExp(r'^\d{9}$').hasMatch(cleaned)) return 'Μη έγκυρος ΑΦΜ';
    return null;
  }
  
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) return null; // Optional
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '');
    if (!RegExp(r'^(\+30)?[0-9]{10}$').hasMatch(cleaned)) return 'Μη έγκυρος αριθμός τηλεφώνου';
    return null;
  }
  
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return null; // Optional
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) return 'Μη έγκυρο email';
    return null;
  }
  
  // Budget Validators
  static String? validateBudgetAmount(String? amount) {
    if (amount == null || amount.isEmpty) return 'Εισάγετε ποσό budget';
    final parsed = double.tryParse(amount);
    if (parsed == null) return 'Μη έγκυρος αριθμός';
    if (parsed <= 0) return 'Το ποσό πρέπει να είναι θετικός αριθμός';
    return null;
  }
  
  // Batch Validation
  static ValidationResult validateReceipt({
    required DateTime? date,
    required int? supplierId,
    required String? paymentMethod,
    required List<ReceiptItemInput> items,
  }) {
    final errors = <String>[];
    
    final dateError = validateReceiptDate(date);
    if (dateError != null) errors.add(dateError);
    
    final supplierError = validateSupplierId(supplierId);
    if (supplierError != null) errors.add(supplierError);
    
    final paymentError = validatePaymentMethod(paymentMethod);
    if (paymentError != null) errors.add(paymentError);
    
    if (items.isEmpty) {
      errors.add('Η απόδειξη πρέπει να έχει τουλάχιστον ένα είδος');
    }
    
    // Edge Case: Αρνητικές τιμές
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.quantity <= 0) errors.add('Είδος ${i + 1}: Μη έγκυρη ποσότητα');
      if (item.unitPrice < 0) errors.add('Είδος ${i + 1}: Αρνητική τιμή');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// SPO: Validation result model
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
  
  String get errorMessage => errors.join('\n');
}
```

**Test File:** `test/unit/core/utils/validators_test.dart`

### 3.9 Responsive Layout (`core/widgets/responsive_layout.dart`)

```dart
/// SPO: Responsive wrapper - single source of truth
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.mobile) {
          return mobile;
        }
        if (constraints.maxWidth < Breakpoints.tablet) {
          return tablet ?? mobile;
        }
        return desktop;
      },
    );
  }
}

/// SPO: Breakpoint constants
/// mobile:  <600   → mobile layout
/// tablet:  ≥600   → tablet layout (600-1199)
/// desktop: ≥1200  → desktop layout (1200+)
class Breakpoints {
  Breakpoints._();
  
  /// Mobile: width < 600
  static const double mobile = 600;
  /// Tablet: 600 ≤ width < 1200 (desktop ξεκινά εδώ)
  static const double tablet = 1200;
  
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < tablet;
  }
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
  
  /// Returns number of columns based on screen width
  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return 1;
    if (width < tablet) return 2;
    if (width < 1600) return 3;
    return 4;
  }
}
```

**Test File:** `test/widget/core/widgets/responsive_layout_test.dart`

### 3.10 Auto Suggest Field (`core/widgets/auto_suggest_field.dart`)

```dart
/// SPO: Auto-complete widget - reusable across app
class AutoSuggestField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final Future<List<T>> Function(String) searchFn;
  final String Function(T) displayFn;
  final Widget Function(T) itemBuilder;
  final ValueChanged<T> onSelected;
  final String? Function(T?)? validator;
  final TextEditingController? controller;
  final bool enabled;
  
  const AutoSuggestField({
    super.key,
    required this.label,
    required this.hint,
    required this.searchFn,
    required this.displayFn,
    required this.itemBuilder,
    required this.onSelected,
    this.validator,
    this.controller,
    this.enabled = true,
  });
  
  @override
  State<AutoSuggestField<T>> createState() => _AutoSuggestFieldState<T>();
}

class _AutoSuggestFieldState<T> extends State<AutoSuggestField<T>> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<T> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  T? _selectedItem;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_onFocusChange);
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      setState(() => _suggestions = []);
    }
  }
  
  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () async {
      if (value.isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        final results = await widget.searchFn(value);
        if (mounted) {
          setState(() {
            _suggestions = results;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onChanged: _onChanged,
          validator: (value) => widget.validator(_selectedItem),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
          ),
        ),
        if (_suggestions.isNotEmpty && _focusNode.hasFocus)
          _buildSuggestionsList(),
      ],
    );
  }
  
  Widget _buildSuggestionsList() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final item = _suggestions[index];
            return ListTile(
              title: widget.itemBuilder(item),
              dense: true,
              onTap: () {
                setState(() {
                  _selectedItem = item;
                  _suggestions = [];
                });
                _controller.text = widget.displayFn(item);
                widget.onSelected(item);
                _focusNode.unfocus();
              },
            );
          },
        ),
      ),
    );
  }
}
```

**Test File:** `test/widget/core/widgets/auto_suggest_field_test.dart`

### 3.11 Theme System (`core/theme/app_theme.dart`)

```dart
/// SPO: Theme definitions - single source of truth
/// Τα χρώματα έρχονται από το AppColors (§7.1) — δεν ορίζονται ξανά εδώ.
class AppTheme {
  AppTheme._();
  
  // Colors — SPoT: AppColors (core/theme/app_colors.dart)
  static const Color primaryColor = AppColors.primaryLight;
  static const Color secondaryColor = AppColors.secondaryLight;
  static const Color errorColor = AppColors.error;
  static const Color warningColor = AppColors.warning;
  
  // Light Theme
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimaryLight,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
  
  // Dark Theme
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDark,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}
```

### 3.12 Theme Provider (`core/theme/theme_provider.dart`)

> **SPoT απόφαση (2026-09-09):** Η πηγή αλήθειας για το theme είναι η
> **UserSettings table** (Drift) — ΟΧΙ SharedPreferences. Το ThemeProvider
> κάνει subscribe σε Stream, οπότε η αλλαγή theme είναι reactive/live
> και δουλεύει παντού (multi-window desktop) χωρίς διπλό STORAGE.
> Το `shared_preferences` ΔΕΝ χρησιμοποιείται από το theme feature.
>
> **Υλοποίηση (2026-09-10, Phase 2 Step 4.1):** Συνδέθηκε με `SettingDao`
> (persistence στο user_settings table). Constructor injection: DI με
> `AppDatabase.test()` για testing, default `SettingDao(database)`.

```dart
/// SPO: Theme state management — persistence στο UserSettings table (Drift),
/// reactive μέσω Stream. Δεν χρησιμοποιεί SharedPreferences.
///
/// DI: SettingDao περνιέται από το constructor (για testing με AppDatabase.test()).
/// Default: SettingDao(database) — το global singleton DB.
class ThemeProvider extends ChangeNotifier {
  final SettingDao _settingsDao;
  StreamSubscription<ThemeMode?>? _sub;
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider({SettingDao? settingsDao})
      : _settingsDao = settingsDao ?? SettingDao(database);
  
  ThemeMode get themeMode => _themeMode;
  Stream<ThemeMode> get themeStream => _streamController.stream;
  
  Future<void> initialize() async {
    _themeMode = await _settingsDao.getThemeMode();
    notifyListeners();
    _sub ??= _settingsDao.watchThemeMode().listen(_onDbThemeChanged);
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    await _settingsDao.setThemeMode(mode);
    _applyThemeMode(mode);
  }
  
  void _onDbThemeChanged(ThemeMode? mode) {
    if (mode == null) return;
    _applyThemeMode(mode);
  }
  
  void _applyThemeMode(ThemeMode mode) {
    final changed = mode != _themeMode;
    _themeMode = mode;
    if (changed) { _streamController.add(mode); notifyListeners(); }
  }
  
  @override
  void dispose() { _sub?.cancel(); _streamController.close(); super.dispose(); }
}
```

**SPoT Theme settings:** Η αποθήκευση/ανάγνωση γίνεται μόνο μέσω του `SettingDao`
(§4.3), στο table `user_settings`, key `'theme_mode'`, value = string με τον
δείκτη του `ThemeMode` (`'0'`=system, `'1'`=light, `'2'`=dark), type `'int'`.

> **Υλοποίηση (2026-09-10):** Πλήρως **SettingDao-backed** — το `ThemeProvider`
> διαβάζει `getThemeMode()` στο `initialize()` και γίνεται reactive μέσω
> `watchThemeMode()`. Το προηγούμενο in-memory stub (Phase 1) καταργήθηκε.

### 3.13 Extensions (`core/utils/extensions.dart`)

```dart
/// SPO: Dart extensions - reusable extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  
  /// Check if string is numeric
  bool get isNumeric => double.tryParse(this) != null;
  
  /// Remove extra whitespace
  String get removeExtraWhitespace => replaceAll(RegExp(r'\s+'), ' ').trim();
}

extension DateTimeExtensions on DateTime {
  /// Check if same day
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
  
  /// Check if today
  bool get isToday => isSameDay(DateTime.now());
  
  /// Check if yesterday
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  
  /// Get start of day
  DateTime get startOfDay => DateTime(year, month, day);
  
  /// Get end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  
  /// Get start of month
  DateTime get startOfMonth => DateTime(year, month, 1);
  
  /// Get end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);
}

extension DoubleExtensions on double {
  /// Format as currency
  String toCurrency() => CurrencyFormatter.format(this);
  
  /// Format with 2 decimal places
  String toFixed2() => toStringAsFixed(2);
  
  /// Check if approximately equal
  bool approximates(double other, {double epsilon = 0.001}) =>
      (this - other).abs() < epsilon;
}
```

---

## 4. Database Layer (Drift)

### 4.1 Database Class (`core/database/app_database.dart`)

> **SPoT μονοπατιού DB**: `resolveDatabaseFile()` (`core/database/database_file.dart`) —
> το μοναδικό σημείο που υπολογίζει τη διαδρομή του αρχείου. Το χρησιμοποιούν τόσο το
> `AppDatabase` (άνοιγμα) όσο και το `BackupService` (§4.5) → καμία αλλαγή τοποθεσίας
> δεν απαιτεί αλλαγή σε 2+ σημεία. Χωρίς cyclic dependency: και τα δύο εξαρτώνται μόνο
> από το `database_file.dart`, όχι μεταξύ τους.

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../debug/app_logger.dart';
import '../debug/debug_config.dart';
import 'database_file.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

/// SPO: Main Drift database class
@DriftDatabase(tables: [
  Categories,
  Suppliers,
  Items,
  Receipts,
  ReceiptItems,
  Payments,
  PriceHistory,
  Budgets,
  Tags,
  ReceiptTags,
  UserSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  // ΚΡΙΣΙΜΟ: Αποθήκευση ημερομηνιών ως ISO8601 TEXT (όχι unix timestamps).
  // Χωρίς αυτό, το Drift αποθηκεύει DateTime ως INTEGER και οι συγκρίσεις
  // τύπου `r.receipt_date >= '2026-01-01'` αποτυγχάνουν σιωπηλά
  // (στη SQLite κάθε αριθμός < κάθε κείμενο).
  // Πρέπει να οριστεί ΠΡΙΝ δημιουργηθεί οποιοδήποτε δεδομένο.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
  
  // Bump version when schema changes — SPoT: AppConstants.dbVersion
  @override
  int get schemaVersion => AppConstants.dbVersion;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedAllVersions();
    },
    onUpgrade: (m, from, to) async {
      // Future schema migrations: if (from < 2) { ... }
    },
    beforeOpen: (details) async {
      // ⚠️ ΔΙΟΡΘΩΣΗ: in drift 2.14 ΔΕΝ υπάρχει afterOpen → χρησιμοποιούμε beforeOpen.
      await customStatement('PRAGMA foreign_keys = ON');
      // Data migrations αφορούν ΜΟΝΟ υπάρχουσα βάση (upgrade) — σε fresh
      // install το onCreate έκανε ήδη πλήρες seed ατομικά (1 batch).
      if (!details.wasCreated) {
        await _applyDataMigrations();
      }
    },
  );
  
  /// Seed versioned — κάθε έκδοση seed έχει ξεχωριστή έξοδο
  static const int currentSeedVersion = 1;
  
  Future<void> _seedAllVersions() async {
    await _runSeedV1();
  }
  
  Future<void> _runSeedV1() async {
    // ⚠️ ΔΙΟΡΘΩΣΗ: Χωρίς withDefault(currentDateAndTime), ο εφαρμογή
    // βάζει ρητά τα createdAt/updatedAt (local DateTime, ο converter τα
    // κάνει UTC κατά την αποθήκευση).
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(name: 'Τρόφιμα', icon: const Value('🍽️'), color: const Value('#2196F3'), sortOrder: const Value(1), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Οικιακά', icon: const Value('🏠'), color: const Value('#4CAF50'), sortOrder: const Value(2), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Μεταφορικά', icon: const Value('🚗'), color: const Value('#FF9800'), sortOrder: const Value(3), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Υγεία', icon: const Value('💊'), color: const Value('#E91E63'), sortOrder: const Value(4), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Ένδυση', icon: const Value('👕'), color: const Value('#9C27B0'), sortOrder: const Value(5), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Ψυχαγωγία', icon: const Value('🎮'), color: const Value('#00BCD4'), sortOrder: const Value(6), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Εκπαίδευση', icon: const Value('📚'), color: const Value('#795548'), sortOrder: const Value(7), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Λοιπά', icon: const Value('📦'), color: const Value('#607D8B'), sortOrder: const Value(8), createdAt: now, updatedAt: now),
      ]);
      batch.insertAll(
        userSettings,
        [
          UserSettingsCompanion.insert(key: 'theme_mode', value: const Value('0'), type: const Value('int'), updatedAt: now),
          UserSettingsCompanion.insert(key: 'currency', value: const Value('€'), type: const Value('string'), updatedAt: now),
          UserSettingsCompanion.insert(key: 'default_vat_rate', value: const Value('24.0'), type: const Value('double'), updatedAt: now),
          UserSettingsCompanion.insert(key: 'receipt_number_counter', value: const Value('1'), type: const Value('int'), updatedAt: now),
          // version-stamp ΜΕΣΑ στο ίδιο batch → seed ατομικό (ένα implicit transaction).
          // insertOrReplace + unique(key) → idempotent σε re-run.
          UserSettingsCompanion.insert(key: 'seed_version', value: const Value('1'), type: const Value('int'), updatedAt: now),
        ],
        mode: InsertMode.insertOrReplace,
      );
    });
  }
  
  /// Data migrations — τρέχει σε ΥΠΑΡΧΟΥΣΑ βάση μετά από upgrade
  /// Αυτό είναι ζωτικό: όταν προσθέτουμε νέες default κατηγορίες/ρυθμίσεις,
  /// πρέπει να μπουν και σε υφιστάμενες εγκαταστάσεις (όχι μόνο νέες DBs).
  Future<void> _applyDataMigrations() async {
    final version = await _getSeedVersion();
    if (version < currentSeedVersion) { await _runSeedV1(); }
    // if (version < currentSeedVersion) { await _runSeedV2(); } // νέες νόμιμες versions
  }
  
  Future<int> _getSeedVersion() async {
    final row = await (select(userSettings)
      ..where((s) => s.key.equals('seed_version'))
    ).getSingleOrNull();
    return row != null ? int.tryParse(row.value ?? '') ?? 0 : 0;
  }
  
/// SPO: Close database connection
  @override
  Future<void> close() async {
    await super.close();
  }
}

/// SPO: Database connection factory
///
/// **Timezone:** ΕΠΙΒΑΛΛΕΤΑΙ από το `UtcDateTimeConverter` (§4.2) σε κάθε
/// DateTime column — αποθήκευση UTC, εμφάνιση local. Κανένα .toUtc() manual.
///
/// **SQLCipher (μελλοντικά):** Αν χρειαστεί κρυπτογράφηση DB, αλλάζει μόνο
/// το εσωτερικό αυτής της μεθόδου (NativeDatabase → EncryptedNativeDatabase).
/// Καμία αλλαγή στην υπόλοιπη υποδομή
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final sw = Stopwatch()..start();
    try {
      final file = await resolveDatabaseFile();

      final connection = NativeDatabase.createInBackground(file);

      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance('Database open: ${sw.elapsed.inMilliseconds}ms');
      }
      return connection;
    } catch (e, stackTrace) {
      sw.stop();
      AppLogger.error('Database open failed: $e', stackTrace);
      rethrow;
    }
  });
}

/// SPO: Database singleton
final database = AppDatabase();
```

### 4.2 Drift Tables (`core/database/tables/`)

> **UUID POLICY (μελλοντικό sync / multi-device):** Κάθε "entity" πίνακας έχει
> στήλη `uuid TEXT NOT NULL UNIQUE` με `clientDefault(() => const Uuid().v4())`.
> Τα `id` (autoincrement) παραμένουν για τοπικές αναφορές/foreign keys, αλλά το
> `uuid` είναι το **global identity** — απαραίτητο για μελλοντικό cloud sync
> (χωρίς συγκρούσεις IDs μεταξύ συσκευών). Δεν βάζουμε uuid σε junction tables
> (ReceiptTags) ούτε στο UserSettings (key-based).
> Απαιτούνται σε κάθε entity table file τα imports:
> - `import 'package:uuid/uuid.dart';` (για τη στήλη uuid)
> - `import 'utc_date_time_converter.dart';` (για τα dateTime().map(const UtcDateTimeConverter())() columns)

```dart
// core/database/tables/utc_date_time_converter.dart
import 'package:drift/drift.dart';

/// SPO: UTC TypeConverter — ΕΠΙΒΑΛΛΕΙ την timezone policy στον κώδικα (όχι σε σχόλιο).
/// Αποθήκευση: πάντα UTC. Ανάγνωση: πάντα local timezone.
/// ⚠️ ΔΙΟΡΘΩΣΗ: `storeDateTimeAsText: true` αναλαμβάνει ήδη το DateTime↔String.
/// Ο drift τότε τροφοδοτεί τον converter με DateTime (όχι String), γι' αυτό
/// ο converter είναι TypeConverter<DateTime, DateTime> — χειρίζεται ΜΟΝΟ UTC↔local.
class UtcDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const UtcDateTimeConverter();
  @override
  DateTime fromSql(DateTime fromDb) => fromDb.toLocal();
  @override
  DateTime toSql(DateTime value) => value.toUtc();
}

/// ⚠️ ΔΙΟΡΘΩΣΗ: ΔΕΝ υπάρχει πια helper `utcDateTime()`.
/// Ο drift codegen ΔΕΝ υποστηρίζει function calls σε column builders
/// (σφάλμα: "type 'Null' is not a subtype of type 'MethodInvocation'").
/// Κάθε στήλη ημερομηνίας δηλώνεται INLINE:
///   Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
///
/// ⚠️ ΔΙΟΡΘΩΣΗ: ΔΕΝ χρησιμοποιούμε `withDefault(currentDateAndTime)` —
/// ο Drift εμφανίζει warning "Parameter must accept DateTime" στα mapped
/// columns. Τα createdAt/updatedAt ΔΕΝ έχουν default πλέον· ο κώδικας
/// εφαρμογής/DAO τα θέτει ρητά (DateTime.now()).
```

```dart
// core/database/tables/categories.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Categories table
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get parentId => integer().references(Categories, #id).nullable()();
  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdBy => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
  
  @override
  List<Set<Column>> get uniqueKeys => [{name, parentId}];
}

// core/database/tables/suppliers.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Suppliers table
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get vatNumber => text().nullable().unique()();
  TextColumn get taxOffice => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get postalCode => text().nullable()();
  TextColumn get country => text().withDefault(const Constant('Ελλάδα'))();
  TextColumn get bankName => text().nullable()();
  TextColumn get bankAccount => text().nullable()();
  TextColumn get iban => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/items.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'categories.dart';
import 'suppliers.dart';
import 'utc_date_time_converter.dart';

/// SPO: Items table
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('τεμ'))();
  RealColumn get unitWeight => real().nullable()();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get maxStock => real().withDefault(const Constant(0))();
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0))();
  RealColumn get lastPrice => real().nullable()();
  IntColumn get lastSupplierId => integer().references(Suppliers, #id).nullable()();
  IntColumn get preferredSupplierId => integer().references(Suppliers, #id).nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isTaxable => boolean().withDefault(const Constant(true))();
  RealColumn get defaultVatRate => real().withDefault(const Constant(24.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
  
  @override
  List<Set<Column>> get uniqueKeys => [{name, categoryId}];
}

// core/database/tables/receipts.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'suppliers.dart';
import 'utc_date_time_converter.dart';

/// SPO: Receipts table
class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptNumber => integer().unique()();
  Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get invoiceSeries => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get vatTotal => real().withDefault(const Constant(0))();
  RealColumn get discountTotal => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/receipt_items.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'receipts.dart';
import 'items.dart';
import 'utc_date_time_converter.dart';

/// SPO: Receipt items table
class ReceiptItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptId => integer().references(Receipts, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
  RealColumn get vatRate => real().withDefault(const Constant(24.0))();
  RealColumn get vatAmount => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get totalPrice => real()();
  RealColumn get totalWithVat => real()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/payments.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'receipts.dart';
import 'utc_date_time_converter.dart';

/// SPO: Payments table
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptId => integer().references(Receipts, #id)();
  RealColumn get amount => real()();
  Column<DateTime> get paymentDate => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get paymentMethod => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/price_history.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'items.dart';
import 'suppliers.dart';
import 'utc_date_time_converter.dart';

/// SPO: Price history table
class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get itemId => integer().references(Items, #id)();
  RealColumn get price => real()();
  RealColumn get vatRate => real().withDefault(const Constant(24.0))();
  Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/budgets.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'categories.dart';
import 'utc_date_time_converter.dart';

/// SPO: Budgets table
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  // NOT NULL: κάθε budget ανήκει σε κατηγορία - δεν υπάρχει "γενικό budget".
  // Αν χρειαστεί γενικό budget, υπολογίζεται ως άθροισμα των category budgets.
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  // Σημείωση: NO spentAmount - το spent υπολογίζεται LIVE μέσω aggregate query στο BudgetDao
  // (δεν αποθηκεύουμε derived/aggregate τιμές που μπορεί να γίνουν stale)
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
  
  @override
  List<Set<Column>> get uniqueKeys => [{categoryId, month, year}];
}

// core/database/tables/tags.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Tags table
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/receipt_tags.dart
import 'package:drift/drift.dart';
import 'receipts.dart';
import 'tags.dart';

/// SPO: Receipt tags junction table
class ReceiptTags extends Table {
  IntColumn get receiptId => integer().references(Receipts, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  
  @override
  Set<Column> get primaryKey => {receiptId, tagId};
}

// core/database/tables/user_settings.dart
import 'package:drift/drift.dart';
import 'utc_date_time_converter.dart';

/// SPO: User settings table
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('string'))();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}
```

### 4.3 Drift DAOs (`core/database/daos/`)

Εξελίχθηκαν και υλοποιήθηκαν 6 DAOs (Phase 2 Step 3), καθένα δικό του
αρχείο `<name>_dao.dart` + `part '<name>_dao.g.dart'`:

| DAO | Αρχείο | Βασικές λειτουργίες |
|---|---|---|
| SettingDao | `setting_dao.dart` | `getSetting/setSetting/watchSetting`, `getThemeMode/setThemeMode/watchThemeMode` |
| CategoryDao | `category_dao.dart` | `watchAllCategories`, `getCategoryById`, `watchCategoryTree`, `watchCategoryWithChildrenRecursively` (recursive CTE), `createCategory`, `updateCategory`, `softDeleteCategory → Future<bool>` |
| SupplierDao | `supplier_dao.dart` | `watchAllSuppliers`, `searchSuppliersByName`, `getSupplierById`, `create/update/softDelete`, `getReceiptCount` |
| ItemDao | `item_dao.dart` | `watchAllItems/ByCategory/ByBarcode`, `searchItemsByName`, `watchLowStock`, `getItemById`, `create/update/softDelete`, `increaseStock` (atomic `currentStock = currentStock + qty`) |
| TagDao | `tag_dao.dart` | `watchAllTags`, `searchTagsByName`, `getTagById`, `createTag → Future<Tag?>`, `updateTag`, `deleteTag`, `watchTagsByReceiptId`, `addTagToReceipt`, `removeTagFromReceipt`, `removeAllTagsFromReceipt` |
| BudgetDao | `budget_dao.dart` | `watchBudget`, `watchBudgetsForMonth`, `upsertBudget`, `watchDashboardSpending` (top-8), μοντέλα `BudgetWithSpent` + `CategorySpending` |

Barrel export: `daos/daos.dart` (`export 'setting_dao.dart';` κ.ο.κ.).

Υλοποίηση & codegen: `@DriftAccessor` + `part 'x.g.dart'` + `with _$XMixin`
(κανονική drift codegen, `dart run build_runner build`). Ο constructor είναι
`XDao(super.db);` (για `use_super_parameters`). Το `app_database.g.dart`
παραμένει ΑΜΕΤΑΒΛΗΤΟ — τα DAOs κάνουν export τα tables, δεν τα αλλάζουν.

Αποκλίσεις από τις ENTIRE §4.3 λεπτομέρειες που κρίθηκαν AGENTS-safe:
- Σημεία όπου το snippet χρησιμοποιούσε `Expression.constant()` → όπου
  χρειαζόταν expression, χρησιμοποιείται `Variable<T>(...)`.
- `insertOnConflictUpdate` στο budgets δεν αρκεί (ΠΚ ≠ UNIQUE (category_id,
  month, year)) → `onConflict: DoUpdate(..., target: [...])`.
- Στα aggregates, το φίλτρο ημερομηνίας μπαίνει ΜΟΝΟ στο LEFT JOIN receipts;
  για να μην αθροίζονται receipt_items εκτός μήνα, το SUM γίνεται
  `SUM(CASE WHEN r.id IS NOT NULL THEN ri.total_with_vat ELSE 0 END)`.
- Όλα τα `row.read<DateTime>()` από customSelect καλούν `.toLocal()`.
- Το BudgetDao (και τα customSelect της εφαρμογής) κάνουν
  `Stopwatch` + `AppLogger.performance` όταν ξεπερνιέται `DebugConfig.slowQueryThreshold`
  (ίδιο μοτίβο με το §4.1).

Διορθώσεις Phase 2 Step 3.1 (review 2026-09-10) — παλιά bug/ασυνέπειες:
- **`BudgetDao._monthBounds`** (όριο μήνα): ο υπολογισμός γινόταν με γυμνά
  strings ημερομηνίας (`'2026-03-01'`). Επειδή η βάση αποθηκεύει `receipt_date`
  ως πλήρες UTC ISO (UtcDateTimeConverter), μια απόδειξη της 1ης το πρωί
  (π.χ. `DateTime(2026,5,1)` → αποθηκευμένο `2026-04-30T21:00:00.000Z`)
  ήταν λεξικογραφικά ΜΙΚΡΟΤΕΡΟ του `'2026-05-01'` → έπεφτε στον προηγούμενο
  μήνα. Διόρθωση: τα bounds υπολογίζονται από το ΤΟΠΙΚΟ μεσονύχτι και
  μετατρέπονται σε UTC:
  `DateTime(year, month, 1).toUtc().toIso8601String()` (ο Dart constructor
  κάνει μόνος roll-over για month=13 → αφαιρέθηκε το ειδικό case για Δεκέμβριο).
  Μία αλλαγή στο `_monthBounds` καλύπτει `watchBudget`, `watchBudgetsForMonth`,
  `watchDashboardSpending`.
- **`ItemDao.increaseStock`**: το `ItemsCompanion.custom` με
  `Variable<DateTime>(DateTime.now())` παρακάμπτει τον UtcDateTimeConverter →
  αποθήκευση τοπικής ώρας αντί UTC. Διόρθωση: `Variable<DateTime>(DateTime.now().toUtc())`.
  (Σημ.: στο custom, `lastPrice: null` σημαίνει «αμετάβλητο», όχι «μηδένισε».)
- **`SettingDao.setSetting`**: `InsertMode.insertOrReplace` στη σύγκρουση UNIQUE
  κάνει DELETE+INSERT → νέο `id` κάθε φορά. Διόρθωση: ίδιο pattern με το
  budget — `onConflict: DoUpdate(..., target: [userSettings.key])` ώστε το id
  να μένει ίδιο.
- **`CategoryDao.createCategory`**: το SQLite `UNIQUE (name, parentId)` δεν
  μπλοκάρει δύο ρίζες (parentId = NULL) με ίδιο name (τα NULL θεωρούνται
  διακεκριμένα). Διόρθωση: app-level έλεγχος πριν το insert — αν υπάρχει ήδη
  ίδιο name με ίδιο parentId (ή τόσο ρίζα όσο και ρίζα) πετιέται
  `CategoryDuplicateNameException`.

```dart
// core/database/daos/receipt_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'receipt_dao.g.dart';

/// SPO: Receipt Data Access Object
@DriftAccessor(tables: [Receipts, ReceiptItems, Payments, Items, Suppliers, Categories, ReceiptTags])
class ReceiptDao extends DatabaseAccessor<AppDatabase> with _$ReceiptDaoMixin {
  ReceiptDao(AppDatabase db) : super(db);
  
  /// Watch all receipts (reactive)
  /// Οι ημερομηνίες εισόδου μετατρέπονται σε UTC πριν τη σύγκριση
  /// (η βάση αποθηκεύει UTC μέσω UtcDateTimeConverter).
  Stream<List<Receipt>> watchAllReceipts({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    String? paymentStatus,
  }) {
    var query = select(receipts);
    
    if (startDate != null) {
      query = query..where((r) => r.receiptDate.isBiggerOrEqualValue(startDate.toUtc()));
    }
    if (endDate != null) {
      query = query..where((r) => r.receiptDate.isSmallerOrEqualValue(endDate.toUtc()));
    }
    if (supplierId != null) {
      query = query..where((r) => r.supplierId.equals(supplierId));
    }
    if (paymentStatus != null) {
      query = query..where((r) => r.paymentStatus.equals(paymentStatus));
    }
    
    query = query..orderBy([(r) => OrderingTerm.desc(r.receiptDate)]);
    
    return query.watch();
  }
  
  /// Get receipt by ID
  Future<Receipt?> getReceiptById(int id) async {
    return (select(receipts)..where((r) => r.id.equals(id))).getSingleOrNull();
  }
  
  /// Get receipt items by receipt ID
  Stream<List<ReceiptItem>> watchReceiptItems(int receiptId) {
    return (select(receiptItems)
      ..where((ri) => ri.receiptId.equals(receiptId))
    ).watch();
  }
  
  /// Get next receipt number (για προεπισκόπηση σε UI form, π.χ. "Απόδειξη #1234")
  Future<int> getNextReceiptNumber() async {
    final lastReceipt = await (select(receipts)
      ..limit(1)
      ..orderBy([(r) => OrderingTerm.desc(r.receiptNumber)])
    ).getSingleOrNull();
    return (lastReceipt?.receiptNumber ?? 0) + 1;
  }
  
  /// Create receipt with items (atomic transaction)
  Future<int> createReceipt(ReceiptInput input) async {
    return await transaction(() async {
      // 1. Get next receipt number (atomic)
      final lastReceipt = await (select(receipts)
        ..limit(1)
        ..orderBy([(r) => OrderingTerm.desc(r.receiptNumber)])
      ).getSingleOrNull();
      
      final nextNumber = (lastReceipt?.receiptNumber ?? 0) + 1;
      
      // 2. Insert receipt
      final receiptId = await into(receipts).insert(ReceiptsCompanion.insert(
        receiptNumber: nextNumber,
        receiptDate: input.date,
        supplierId: input.supplierId,
        invoiceNumber: Value(input.invoiceNumber),
        invoiceSeries: Value(input.invoiceSeries),
        paymentMethod: Value(input.paymentMethod),
        notes: Value(input.notes),
      ));
      
      // 3. Insert receipt items
      for (var itemInput in input.items) {
        final item = _calculateReceiptItem(
          receiptId: receiptId,
          itemId: itemInput.itemId,
          quantity: itemInput.quantity,
          unitPrice: itemInput.unitPrice,
          vatRate: itemInput.vatRate,
          discount: itemInput.discount,
        );
        
        await into(receiptItems).insert(ReceiptItemsCompanion.insert(
          receiptId: receiptId,
          itemId: itemInput.itemId,
          quantity: Value(item.quantity),
          unitPrice: item.unitPrice,
          vatRate: Value(item.vatRate),
          vatAmount: Value(item.vatAmount),
          discount: Value(item.discount),
          totalPrice: item.totalPrice,
          totalWithVat: item.totalWithVat,
        ));
        
        // Update item stock
        await _updateItemStock(
          itemId: itemInput.itemId,
          quantity: itemInput.quantity,
          unitPrice: itemInput.unitPrice,
          supplierId: input.supplierId,
        );
        
        // Insert price history
        await into(priceHistory).insert(PriceHistoryCompanion.insert(
          itemId: itemInput.itemId,
          price: itemInput.unitPrice,
          vatRate: Value(itemInput.vatRate),
          receiptDate: input.date,
          supplierId: input.supplierId,
          quantity: Value(itemInput.quantity),
        ));
      }
      
      // 4. Update receipt totals
      await _updateReceiptTotals(receiptId);
      
      // 5. Insert payments
      for (var paymentInput in input.payments) {
        await into(payments).insert(PaymentsCompanion.insert(
          receiptId: receiptId,
          amount: paymentInput.amount,
          paymentDate: paymentInput.date,
          paymentMethod: paymentInput.method,
          reference: Value(paymentInput.reference),
        ));
      }
      
      // 6. Update payment status
      await _updatePaymentStatus(receiptId);
      
      return receiptId;
    });
  }
  
  /// Update receipt item (with recalculation)
  Future<void> updateReceiptItem(int receiptId, int itemId, ReceiptItemUpdate update) async {
    await transaction(() async {
      // 1. Update the item
      await (update(receiptItems)
        ..where((ri) => ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
        .write(ReceiptItemsCompanion(
          quantity: Value(update.quantity),
          unitPrice: Value(update.unitPrice),
          vatRate: Value(update.vatRate),
          discount: Value(update.discount),
          // Recalculate totals
          totalPrice: Value(_calculateTotal(update.quantity, update.unitPrice, update.discount)),
          totalWithVat: Value(_calculateTotalWithVat(update.quantity, update.unitPrice, update.vatRate, update.discount)),
          vatAmount: Value(_calculateVat(update.quantity, update.unitPrice, update.vatRate, update.discount)),
        ));
      
      // 2. Recalculate receipt totals
      await _updateReceiptTotals(receiptId);
      
      // 3. Update item stock
      await _recalculateItemStock(itemId);
    });
  }
  
  /// Delete receipt item (with recalculation)
  Future<void> deleteReceiptItem(int receiptId, int itemId) async {
    await transaction(() async {
      // 1. Delete the item
      await (delete(receiptItems)
        ..where((ri) => ri.receiptId.equals(receiptId) & ri.itemId.equals(itemId)))
        .go();
      
      // 2. Recalculate receipt totals
      await _updateReceiptTotals(receiptId);
      
      // 3. Recalculate item stock
      await _recalculateItemStock(itemId);
    });
  }
  
  /// Delete receipt
  Future<void> deleteReceipt(int id) async {
    await transaction(() async {
      // Get all items for stock recalculation
      final items = await (select(receiptItems)
        ..where((ri) => ri.receiptId.equals(id))
      ).get();
      
      // Delete receipt tags (αποφυγή orphan records / FK violation)
      await (delete(receiptTags)..where((rt) => rt.receiptId.equals(id))).go();
      
      // Delete receipt items
      await (delete(receiptItems)..where((ri) => ri.receiptId.equals(id))).go();
      
      // Delete payments
      await (delete(payments)..where((p) => p.receiptId.equals(id))).go();
      
      // Delete receipt
      await (delete(receipts)..where((r) => r.id.equals(id))).go();
      
      // Recalculate stock for affected items
      for (var item in items) {
        await _recalculateItemStock(item.itemId);
      }
    });
  }
  
  // Private helpers
  
  ReceiptItemData _calculateReceiptItem({
    required int receiptId,
    required int itemId,
    required double quantity,
    required double unitPrice,
    required double vatRate,
    required double discount,
  }) {
    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    final taxableAmount = subtotal - discountAmount;
    final vatAmount = taxableAmount * (vatRate / 100);
    final totalWithVat = taxableAmount + vatAmount;
    
    return ReceiptItemData(
      receiptId: receiptId,
      itemId: itemId,
      quantity: quantity,
      unitPrice: unitPrice,
      vatRate: vatRate,
      vatAmount: vatAmount,
      discount: discount,
      totalPrice: taxableAmount,
      totalWithVat: totalWithVat,
      createdAt: DateTime.now(),
    );
  }
  
  Future<void> _updateItemStock({
    required int itemId,
    required double quantity,
    required double unitPrice,
    required int supplierId,
  }) async {
    await (update(items)..where((i) => i.id.equals(itemId)))
        .write(ItemsCompanion(
          // Parameterized expression - NO raw string interpolation
          currentStock: items.currentStock + constant(quantity),
          lastPrice: Value(unitPrice),
          lastSupplierId: Value(supplierId),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  Future<void> _recalculateItemStock(int itemId) async {
    // Calculate total stock from all receipt items
    final result = await customSelect(
      'SELECT COALESCE(SUM(quantity), 0) as total_stock '
      'FROM receipt_items '
      'WHERE item_id = ?',
      variables: [Variable.withInt(itemId)],
    ).getSingleOrNull();
    
    final totalStock = result?.read<double>('total_stock') ?? 0;
    
    await (update(items)..where((i) => i.id.equals(itemId)))
        .write(ItemsCompanion(
          currentStock: Value(totalStock),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  Future<void> _updateReceiptTotals(int receiptId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total_price), 0) as total, '
      'COALESCE(SUM(vat_amount), 0) as vat, '
      'COALESCE(SUM((quantity * unit_price) * (discount / 100.0)), 0) as discount '
      'FROM receipt_items '
      'WHERE receipt_id = ?',
      variables: [Variable.withInt(receiptId)],
    ).getSingleOrNull();
    
    // total_amount = Σ total_price (μετά από line discount, πριν ΦΠΑ)
    final total = result?.read<double>('total') ?? 0;
    final vat = result?.read<double>('vat') ?? 0;
    final totalDiscount = result?.read<double>('discount') ?? 0;
    
    await (update(receipts)..where((r) => r.id.equals(receiptId)))
        .write(ReceiptsCompanion(
          totalAmount: Value(total),
          vatTotal: Value(vat),
          discountTotal: Value(totalDiscount),
          remainingAmount: Value(total + vat - await _getPaidAmount(receiptId)),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  Future<double> _getPaidAmount(int receiptId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as paid '
      'FROM payments '
      'WHERE receipt_id = ?',
      variables: [Variable.withInt(receiptId)],
    ).getSingleOrNull();
    
    return result?.read<double>('paid') ?? 0;
  }
  
  Future<void> _updatePaymentStatus(int receiptId) async {
    final receipt = await getReceiptById(receiptId);
    if (receipt == null) return;
    
    final paidAmount = await _getPaidAmount(receiptId);
    // remaining = (total χωρίς ΦΠΑ + ΦΠΑ) - πληρωμένα = μεικτό υπόλοιπο
    final remaining = receipt.totalAmount + receipt.vatTotal - paidAmount;
    
    String status;
    if (remaining <= 0) {
      status = 'paid';
    } else if (paidAmount > 0) {
      status = 'partial';
    } else {
      status = 'pending';
    }
    
    await (update(receipts)..where((r) => r.id.equals(receiptId)))
        .write(ReceiptsCompanion(
          paidAmount: Value(paidAmount),
          remainingAmount: Value(remaining),
          paymentStatus: Value(status),
          updatedAt: Value(DateTime.now()),
        ));
  }
  
  double _calculateTotal(double quantity, double unitPrice, double discount) {
    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    return subtotal - discountAmount;
  }
  
  double _calculateVat(double quantity, double unitPrice, double vatRate, double discount) {
    final taxable = _calculateTotal(quantity, unitPrice, discount);
    return taxable * (vatRate / 100);
  }
  
  double _calculateTotalWithVat(double quantity, double unitPrice, double vatRate, double discount) {
    final taxable = _calculateTotal(quantity, unitPrice, discount);
    final vat = _calculateVat(quantity, unitPrice, vatRate, discount);
    return taxable + vat;
  }
}

/// SPoΤ: Τα input types βρίσκονται στο DOMAIN layer (§5.1.3):
///   - ReceiptInput
///   - ReceiptItemInput
///   - PaymentInput
///   - ReceiptItemUpdate
/// Ο ReceiptDao τα εισάγει με import από
/// `features/receipt/domain/models/receipt_input.dart` — ΔΕΝ ορίζονται ξανά εδώ
/// (αποφυγή name collision αν βρεθούν στο ίδιο scope).

class ReceiptItemData {
  final int receiptId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double vatAmount;
  final double discount;
  final double totalPrice;
  final double totalWithVat;
  final DateTime createdAt;
  
  const ReceiptItemData({
    required this.receiptId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.vatAmount,
    required this.discount,
    required this.totalPrice,
    required this.totalWithVat,
    required this.createdAt,
  });
}
```

```dart
// core/database/daos/budget_dao.dart
import 'package:drift/drift.dart';
import '../../debug/app_logger.dart';
import '../../debug/debug_config.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'budget_dao.g.dart';

/// SPO: Budget Data Access Object
@DriftAccessor(tables: [Budgets, Categories, ReceiptItems, Receipts, Items])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  // ---------- Month boundaries (UTC ISO, consistent with stored ISO) ----------
  // DIOORTH 2026-09-10: τα όρια υπολογίζονται από το ΤΟΠΙΚΟ μεσονύχτι και
  // μετατρέπονται σε UTC. Γυμνά strings ημερομηνίας ('2026-05-01') ήταν
  // λεξικογραφικά ΜΕΓΑΛΥΤΕΡΑ από το πλήρες ISO '2026-04-30T21:00:00.000Z'
  // (απόδειξη 1ης το πρωί → έπεφτε στον προηγούμενο μήνα).
  ({String start, String end}) _monthBounds(int month, int year) {
    final start = DateTime(year, month, 1).toUtc().toIso8601String();
    final end = DateTime(year, month + 1, 1).toUtc().toIso8601String();
    return (start: start, end: end);
  }

  // ---------- Row mappers ----------

  BudgetWithSpent _mapBudgetRow(QueryRow row, int month, int year) {
    return BudgetWithSpent(
      budget: Budget(
        id: row.read<int>('id'),
        uuid: row.read<String>('uuid'),
        categoryId: row.read<int>('category_id'),
        month: row.read<int>('month'),
        year: row.read<int>('year'),
        amount: row.read<double>('amount'),
        notes: row.readNullable<String>('notes'),
        createdAt: row.read<DateTime>('created_at').toLocal(),
        updatedAt: row.read<DateTime>('updated_at').toLocal(),
      ),
      spent: row.read<double>('spent'),
      amount: row.read<double>('amount'),
      categoryId: row.read<int>('category_id'),
      month: month,
      year: year,
    );
  }

  // ---------- Core queries ----------

  /// Watch budget with live spent calculation (reactive)
  Stream<BudgetWithSpent?> watchBudget(
      int categoryId, int month, int year) {
    final bounds = _monthBounds(month, year);
    final query = customSelect(
      'SELECT '
      'b.id as id, '
      'b.uuid as uuid, '
      'b.category_id as category_id, '
      'b.month as month, '
      'b.year as year, '
      'b.amount as amount, '
      'b.notes as notes, '
      'b.created_at as created_at, '
      'b.updated_at as updated_at, '
      'COALESCE(SUM(CASE WHEN r.id IS NOT NULL '
      'THEN ri.total_with_vat ELSE 0 END), 0) as spent '
      'FROM budgets b '
      'LEFT JOIN items i ON i.category_id = b.category_id '
      'LEFT JOIN receipt_items ri ON ri.item_id = i.id '
      'LEFT JOIN receipts r ON r.id = ri.receipt_id '
      '  AND r.receipt_date >= ? AND r.receipt_date < ? '
      'WHERE b.category_id = ? AND b.month = ? AND b.year = ? '
      'GROUP BY b.id',
      variables: [
        Variable.withString(bounds.start),
        Variable.withString(bounds.end),
        Variable.withInt(categoryId),
        Variable.withInt(month),
        Variable.withInt(year),
      ],
      readsFrom: {budgets, receiptItems, items, receipts},
    );

    return query.watchSingleOrNull().map((row) {
      final sw = Stopwatch()..start();
      try {
        if (row == null) {
          return BudgetWithSpent(
            budget: null,
            spent: 0,
            amount: 0,
            categoryId: categoryId,
            month: month,
            year: year,
          );
        }
        return _mapBudgetRow(row, month, year);
      } finally {
        sw.stop();
        if (sw.elapsed > DebugConfig.slowQueryThreshold) {
          AppLogger.performance(
              'BudgetDao.watchBudget(cat=$categoryId): ${sw.elapsed.inMilliseconds}ms');
        }
      }
    });
  }

  /// Watch all budgets for a month with live spent (reactive)
  Stream<List<BudgetWithSpent>> watchBudgetsForMonth(int month, int year) {
    final bounds = _monthBounds(month, year);
    final query = customSelect(
      'SELECT '
      'b.id as id, '
      'b.uuid as uuid, '
      'b.category_id as category_id, '
      'b.month as month, '
      'b.year as year, '
      'b.amount as amount, '
      'b.notes as notes, '
      'b.created_at as created_at, '
      'b.updated_at as updated_at, '
      'COALESCE(SUM(CASE WHEN r.id IS NOT NULL '
      'THEN ri.total_with_vat ELSE 0 END), 0) as spent '
      'FROM budgets b '
      'LEFT JOIN items i ON i.category_id = b.category_id '
      'LEFT JOIN receipt_items ri ON ri.item_id = i.id '
      'LEFT JOIN receipts r ON r.id = ri.receipt_id '
      '  AND r.receipt_date >= ? AND r.receipt_date < ? '
      'WHERE b.month = ? AND b.year = ? '
      'GROUP BY b.id',
      variables: [
        Variable.withString(bounds.start),
        Variable.withString(bounds.end),
        Variable.withInt(month),
        Variable.withInt(year),
      ],
      readsFrom: {budgets, receiptItems, items, receipts},
    );

    return query.watch().map((rows) {
      final sw = Stopwatch()..start();
      try {
        return rows.map((r) => _mapBudgetRow(r, month, year)).toList();
      } finally {
        sw.stop();
        if (sw.elapsed > DebugConfig.slowQueryThreshold) {
          AppLogger.performance(
              'BudgetDao.watchBudgetsForMonth($month/$year): ${sw.elapsed.inMilliseconds}ms');
        }
      }
    });
  }

  /// Create or update budget
  Future<void> upsertBudget({
    required int categoryId,
    required int month,
    required int year,
    required double amount,
    String? notes,
  }) async {
    final now = DateTime.now();
    // ΣΗΜΕΙΩΣΗ: insertOnConflictUpdate στοχεύει ΜΟΝΟ το PK (id).
    // Το budgets έχει UNIQUE (category_id, month, year) άρα χρειάζεται
    // explicit onConflict: DoUpdate με target αυτό το UNIQUE.
    await into(budgets).insert(
      BudgetsCompanion.insert(
        categoryId: categoryId,
        month: month,
        year: year,
        amount: amount,
        notes: Value(notes),
        createdAt: now,
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => BudgetsCompanion(
          amount: Value(amount),
          notes: Value(notes),
          // Το createdAt μένει ως έχει (πρώτη δημιουργία), μόνο updatedAt αλλάζει.
          updatedAt: Value(now),
        ),
        target: [budgets.categoryId, budgets.month, budgets.year],
      ),
    );
  }

  /// Top κατηγορίες με spending για τον μήνα (για Dashboard / HomeScreen).
  Stream<List<CategorySpending>> watchDashboardSpending(
      int month, int year) {
    final bounds = _monthBounds(month, year);
    final query = customSelect(
      'SELECT '
      'c.id as category_id, '
      'c.name as category_name, '
      'c.color as color, '
      'c.icon as icon, '
      'COALESCE(SUM(CASE WHEN r.id IS NOT NULL '
      'THEN ri.total_with_vat ELSE 0 END), 0) as spent '
      'FROM categories c '
      'LEFT JOIN items i ON i.category_id = c.id '
      'LEFT JOIN receipt_items ri ON ri.item_id = i.id '
      'LEFT JOIN receipts r ON r.id = ri.receipt_id '
      '  AND r.receipt_date >= ? AND r.receipt_date < ? '
      'WHERE c.is_active = 1 '
      'GROUP BY c.id '
      'ORDER BY spent DESC '
      'LIMIT 8',
      variables: [
        Variable.withString(bounds.start),
        Variable.withString(bounds.end),
      ],
      readsFrom: {categories, items, receiptItems, receipts},
    );

    return query.watch().map(
      (rows) => rows
          .map(
            (r) => CategorySpending(
              categoryId: r.read<int>('category_id'),
              categoryName: r.read<String>('category_name'),
              color: r.readNullable<String>('color'),
              icon: r.readNullable<String>('icon'),
              spent: r.read<double>('spent'),
            ),
          )
          .toList(),
    );
  }
}

// ---------- Models ----------

/// SPO: Budget with live spent amount
class BudgetWithSpent {
  final Budget? budget;
  final double spent;
  final double amount;
  final int categoryId;
  final int month;
  final int year;

  const BudgetWithSpent({
    required this.budget,
    required this.spent,
    required this.amount,
    required this.categoryId,
    required this.month,
    required this.year,
  });

  bool get hasBudget => budget != null;
  double get percentage => amount > 0 ? (spent / amount) * 100 : 0;
  bool get isOverBudget => spent > amount;
  double get remaining => amount - spent;
}

/// SPO: Category spending summary for Dashboard
class CategorySpending {
  final int categoryId;
  final String categoryName;
  final String? color;
  final String? icon;
  final double spent;

  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.icon,
    required this.spent,
  });
}
```
```dart
// core/database/daos/item_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'item_dao.g.dart';

/// SPO: Item Data Access Object
@DriftAccessor(tables: [Items, Categories, Suppliers, ReceiptItems, PriceHistory])
class ItemDao extends DatabaseAccessor<AppDatabase> with _$ItemDaoMixin {
  ItemDao(super.db);

  /// Watch all active items (reactive)
  Stream<List<Item>> watchAllItems() {
    return (select(items)
      ..where((i) => i.isActive.equals(true))
      ..orderBy([(i) => OrderingTerm.asc(i.name)])
    ).watch();
  }

  /// Watch items by category (reactive)
  Stream<List<Item>> watchItemsByCategory(int categoryId) {
    return (select(items)
      ..where((i) => i.isActive.equals(true) & i.categoryId.equals(categoryId))
      ..orderBy([(i) => OrderingTerm.asc(i.name)])
    ).watch();
  }

  /// Watch items by barcode (reactive, exact match)
  Stream<List<Item>> watchItemsByBarcode(String barcode) {
    return (select(items)
      ..where((i) => i.barcode.equals(barcode))
    ).watch();
  }

  /// Search items by name (LIKE query, reactive)
  Stream<List<Item>> searchItemsByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(items)
      ..where((i) => i.isActive.equals(true) & i.name.lower().like(pattern))
      ..orderBy([(i) => OrderingTerm.asc(i.name)])
    ).watch();
  }

  /// Watch low-stock items (reorderLevel > 0 AND currentStock <= reorderLevel, reactive)
  Stream<List<Item>> watchLowStock() {
    return (select(items)
      ..where((i) =>
          i.isActive.equals(true) &
          i.reorderLevel.isBiggerThanValue(0) &
          i.currentStock.isSmallerOrEqual(i.reorderLevel))
      ..orderBy([(i) => OrderingTerm.asc(i.currentStock)])
    ).watch();
  }

  /// Get item by id
  Future<Item?> getItemById(int id) =>
      (select(items)..where((i) => i.id.equals(id))).getSingleOrNull();

  /// Create item
  Future<int> createItem(ItemsCompanion companion) =>
      into(items).insert(companion);

  /// Update item (full recalc handled by caller where needed)
  Future<bool> updateItem(ItemsCompanion companion) =>
      update(items).replace(companion);

  /// Soft delete (isActive = false)
  Future<void> softDeleteItem(int id) async {
    await (update(items)..where((i) => i.id.equals(id)))
        .write(ItemsCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Αύξηση stock (π.χ. κατά καταχώρηση απόδειξης).
  /// Atomic: `currentStock = currentStock + quantity`.
  /// ΣΗΜΕΙΩΣΗ: χρησιμοποιεί ItemsCompanion.custom — το `update().write()`
  /// δέχεται RawValuesInsertable (το fail σωστά ως UPDATE με expressions).
  /// DIOORTH 2026-09-10: στο custom ο UtcDateTimeConverter παρακάμπτεται →
  /// το updatedAt πρέπει ρητά `.toUtc()` για ομοιόμορφη αποθήκευση UTC.
  Future<void> increaseStock(
    int itemId,
    double quantity, {
    double? unitPrice,
    int? supplierId,
  }) async {
    await (update(items)..where((i) => i.id.equals(itemId))).write(
      ItemsCompanion.custom(
        currentStock: items.currentStock + Variable<double>(quantity),
        lastPrice: unitPrice == null ? null : Variable<double>(unitPrice),
        lastSupplierId:
            supplierId == null ? null : Variable<int>(supplierId),
        updatedAt: Variable<DateTime>(DateTime.now().toUtc()),
      ),
    );
  }
}

// core/database/daos/category_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'category_dao.g.dart';

/// SPO: Category Data Access Object
@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// Watch all active categories (reactive)
  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
      ..where((c) => c.isActive.equals(true))
      ..orderBy([
        (c) => OrderingTerm.asc(c.level),
        (c) => OrderingTerm.asc(c.sortOrder),
      ])
    ).watch();
  }

  /// Get category by id
  Future<Category?> getCategoryById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// Watch category tree (parent/child groups, reactive)
  Stream<List<Category>> watchCategoryTree() {
    return (select(categories)
      ..orderBy([
        (c) => OrderingTerm.asc(c.level),
        (c) => OrderingTerm.asc(c.parentId),
        (c) => OrderingTerm.asc(c.sortOrder),
      ])
    ).watch();
  }

  /// Watch μία κατηγορία μαζί με όλα τα έμμεσα παιδιά της (recursive CTE).
  /// Χρησιμεύει π.χ. στο Budget: το spent της γονικής αθροίζει και τα παιδιά τους.
  Stream<List<Category>> watchCategoryWithChildrenRecursively(int rootId) {
    final query = customSelect(
      'WITH RECURSIVE tree AS ('
      'SELECT * FROM categories WHERE id = ? '
      'UNION ALL '
      'SELECT c.* FROM categories c '
      'JOIN tree t ON c.parent_id = t.id'
      ') SELECT * FROM tree ORDER BY level, sort_order, name',
      variables: [Variable.withInt(rootId)],
      readsFrom: {categories},
    );
    return query.watch().map((rows) => rows
        .map((r) => Category(
              id: r.read<int>('id'),
              uuid: r.read<String>('uuid'),
              name: r.read<String>('name'),
              description: r.readNullable<String>('description'),
              icon: r.readNullable<String>('icon'),
              color: r.readNullable<String>('color'),
              parentId: r.readNullable<int>('parent_id'),
              level: r.read<int>('level'),
              sortOrder: r.read<int>('sort_order'),
              isActive: r.read<bool>('is_active'),
              createdBy: r.readNullable<String>('created_by'),
              createdAt: r.read<DateTime>('created_at').toLocal(),
              updatedAt: r.read<DateTime>('updated_at').toLocal(),
            ))
        .toList());
  }

  /// Create category.
  /// DIOORTH 2026-09-10: app-level έλεγχος duplicate — το SQLite UNIQUE
  /// (name, parentId) δεν μπλοκάρει δύο ρίζες (parentId=NULL) με ίδιο name
  /// (τα NULL θεωρούνται διακεκριμένα). Ίδιο name + ίδιο parentId (ή ρίζα-ρίζα)
  /// → CategoryDuplicateNameException.
  Future<int> createCategory(CategoriesCompanion companion) async {
    final name = companion.name.value;
    final parentId =
        companion.parentId.present ? companion.parentId.value : null;

    final existing = await (select(categories)
          ..where((c) =>
              c.name.equals(name) &
              (parentId == null
                  ? c.parentId.isNull()
                  : c.parentId.equals(parentId))))
        .get();

    if (existing.isNotEmpty) {
      throw CategoryDuplicateNameException(name);
    }

    return into(categories).insert(companion);
  }

  /// Update category
  Future<bool> updateCategory(CategoriesCompanion companion) =>
      update(categories).replace(companion);

  /// Soft delete (isActive = false).
  /// Επιστρέφει false αν υπάρχουν ενεργά παιδιά (αποτροπή ορφανών στο δέντρο).
  Future<bool> softDeleteCategory(int id) async {
    final activeChildren = await (select(categories)
          ..where((c) => c.parentId.equals(id) & c.isActive.equals(true)))
        .get();
    if (activeChildren.isNotEmpty) {
      return false;
    }
    await (update(categories)..where((c) => c.id.equals(id)))
        .write(CategoriesCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
    return true;
  }
}

// core/database/daos/supplier_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'supplier_dao.g.dart';

/// SPO: Supplier Data Access Object
@DriftAccessor(tables: [Suppliers, Receipts])
class SupplierDao extends DatabaseAccessor<AppDatabase> with _$SupplierDaoMixin {
  SupplierDao(super.db);

  /// Watch all active suppliers (reactive)
  Stream<List<Supplier>> watchAllSuppliers() {
    return (select(suppliers)
      ..where((s) => s.isActive.equals(true))
      ..orderBy([(s) => OrderingTerm.asc(s.name)])
    ).watch();
  }

  /// Search suppliers by name (LIKE query, reactive)
  Stream<List<Supplier>> searchSuppliersByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(suppliers)
      ..where((s) => s.isActive.equals(true) & s.name.lower().like(pattern))
      ..orderBy([(s) => OrderingTerm.asc(s.name)])
    ).watch();
  }

  /// Get supplier by id
  Future<Supplier?> getSupplierById(int id) =>
      (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Create supplier
  Future<int> createSupplier(SuppliersCompanion companion) =>
      into(suppliers).insert(companion);

  /// Update supplier
  Future<bool> updateSupplier(SuppliersCompanion companion) =>
      update(suppliers).replace(companion);

  /// Soft delete (isActive = false)
  Future<void> softDeleteSupplier(int id) async {
    await (update(suppliers)..where((s) => s.id.equals(id)))
        .write(SuppliersCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Πλήθος αποδείξεων ενός προμηθευτή (για UI badges / στοιχεία ασφαλείας)
  Future<int> getReceiptCount(int id) async {
    final row = await (customSelect(
      'SELECT COUNT(*) as count FROM receipts WHERE supplier_id = ?',
      variables: [Variable.withInt(id)],
      readsFrom: {receipts},
    ))
        .getSingle();
    return row.read<int>('count');
  }
}
```
```dart
// core/database/daos/tag_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'tag_dao.g.dart';

/// SPO: Tag Data Access Object (tags + receipt_tags)
@DriftAccessor(tables: [Tags, ReceiptTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// Watch all tags (reactive)
  Stream<List<Tag>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Search tags by name (LIKE, reactive)
  Stream<List<Tag>> searchTagsByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(tags)
      ..where((t) => t.name.lower().like(pattern))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
    ).watch();
  }

  /// Get tag by id
  Future<Tag?> getTagById(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Create tag (αν υπάρχει ήδη με το ίδιο name → null / UNIQUE constraint)
  /// ΣΗΜΕΙΩΣΗ: insertReturningOrNull + insertOrIgnore = upsert με εισαγωγή
  /// timestamp δημιουργίας. Δεν χρησιμοποιείται insertOnConflictUpdate γιατί
  /// δεν θες mirror-update σε duplicate.
  Future<Tag?> createTag(String name, {String? color}) =>
      into(tags).insertReturningOrNull(
        TagsCompanion.insert(
          name: name,
          color: Value(color),
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Update tag
  Future<bool> updateTag(TagsCompanion companion) =>
      update(tags).replace(companion);

  /// Delete tag (αφαιρεί και τις ενώσεις receipt_tags)
  Future<void> deleteTag(int id) async {
    await transaction(() async {
      await (delete(receiptTags)..where((rt) => rt.tagId.equals(id))).go();
      await (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Tags ενός receipt (reactive)
  Stream<List<Tag>> watchTagsByReceiptId(int receiptId) {
    final query = select(receiptTags).join([
      innerJoin(tags, tags.id.equalsExp(receiptTags.tagId)),
    ])
      ..where(receiptTags.receiptId.equals(receiptId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(tags)).toList());
  }

  /// Προσθήκη tag σε receipt (idempotent)
  Future<void> addTagToReceipt(int receiptId, int tagId) async {
    await into(receiptTags).insert(
      ReceiptTagsCompanion.insert(receiptId: receiptId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Αφαίρεση tag από receipt
  Future<void> removeTagFromReceipt(int receiptId, int tagId) async {
    await (delete(receiptTags)
      ..where((rt) => rt.receiptId.equals(receiptId) & rt.tagId.equals(tagId))
    ).go();
  }

  /// Αφαίρεση όλων των tags ενός receipt
  Future<void> removeAllTagsFromReceipt(int receiptId) async {
    await (delete(receiptTags)
      ..where((rt) => rt.receiptId.equals(receiptId))
    ).go();
  }
}
```
```dart
// core/database/daos/setting_dao.dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'setting_dao.g.dart';

/// SPO: User settings Data Access Object
/// SPoT αποθήκευσης ρυθμίσεων (π.χ. theme). Η UserSettings table είναι
/// η ΜΟΝΗ πηγή αλήθειας — κανένα SharedPreferences για theme.
@DriftAccessor(tables: [UserSettings])
class SettingDao extends DatabaseAccessor<AppDatabase> with _$SettingDaoMixin {
  SettingDao(super.db);

  static const themeKey = 'theme_mode';

  /// Read a setting by key (as string, nullable)
  Future<String?> getSetting(String key) async {
    final row = await (select(userSettings)
      ..where((s) => s.key.equals(key))
    ).getSingleOrNull();
    return row?.value;
  }

  /// Write a setting by key (upsert)
  /// DIOORTH 2026-09-10: DoUpdate (όχι insertOrReplace) — σε αντίθετη
  /// περίπτωση το UNIQUE conflict έκανε DELETE+INSERT (νέο id κάθε φορά).
  Future<void> setSetting(String key, String value, {String type = 'string'}) async {
    final now = DateTime.now();
    await into(userSettings).insert(
      UserSettingsCompanion.insert(
        key: key,
        value: Value(value),
        type: Value(type),
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => UserSettingsCompanion(
          value: Value(value),
          type: Value(type),
          updatedAt: Value(now),
        ),
        target: [userSettings.key],
      ),
    );
  }

  /// Watch a setting by key (reactive stream)
  Stream<String?> watchSetting(String key) {
    return (select(userSettings)
      ..where((s) => s.key.equals(key))
    ).watchSingleOrNull().map((row) => row?.value);
  }

  // --- Theme helpers ---

  /// Watch theme mode (reactive) — null/άκυρο → system
  Stream<ThemeMode?> watchThemeMode() => watchSetting(themeKey).map(_parseThemeMode);

  /// Φόρτωση theme mode (single-shot για το startup)
  Future<ThemeMode> getThemeMode() async {
    final value = await getSetting(themeKey);
    return _parseThemeMode(value) ?? ThemeMode.system;
  }

  /// Αποθήκευση theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await setSetting(themeKey, '${mode.index}', type: 'int');
  }

  /// '0'=system, '1'=light, '2'=dark (ή null όταν δεν υπάρχει/άκυρο)
  ThemeMode? _parseThemeMode(String? value) {
    if (value == null) return null;
    final index = int.tryParse(value);
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return null;
    }
    return ThemeMode.values[index];
  }
}
```

### 4.4 Drift Migrations (`core/database/migrations/`)

```dart
// Drift handles migrations through the MigrationStrategy in AppDatabase
// Example of future migration:

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
    await _seedAllVersions();
  },
  onUpgrade: (m, from, to) async {
    // Example: Migration from v1 to v2
    if (from < 2) {
      // Add new column
      await m.addColumn(items, items.sku);
      
      // Create new table
      await m.createTable(tags);
      await m.createTable(receiptTags);
    }
    
    // Example: Migration from v2 to v3
    if (from < 3) {
      // Rename column
      await m.renameColumn(suppliers, 'phone', 'landline');
    }
  },
  beforeOpen: (details) async {
    // Enable foreign keys
    await customStatement('PRAGMA foreign_keys = ON');
  },
);
```

### 4.5 Database Backup & Restore (`core/database/backup/`)

> **Πολιτική:** Τα δεδομένα είναι ο θησαυρός της εφαρμογής. Χωρίς backup,
> ο χρήστης χάνει όλα τα οικονομικά δεδομένα του (αποδείξεις, προμηθευτές,
> ιστορικό τιμών). Το backup πρέπει να υπάρχει από τον ΠΡΩΤΟ release.

```dart
// core/database/backup/backup_service.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import '../app_database.dart';

/// SPO: Backup & Restore service
/// Εξάγει/εισάγει τη βάση + attachments σε ZIP αρχείο.
class BackupService {
  final AppDatabase _db;
  BackupService(this._db);

  static const String _backupDirName = 'backups';
  
  /// Κατασκευή backup φακέλου: <appDocuments>/backups/
  Future<Directory> _backupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(appDir.path, _backupDirName));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return backupDir;
  }
  
  /// Export: ZIP (.db + attachments folder + manifest.json)
  Future<File> createBackup({String? name}) async {
    final backupDir = await _backupDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:\.]'), '-');
    final fileName = name ?? 'backup_$timestamp';
    final zipPath = p.join(backupDir.path, '$fileName.zip');
    
    // 1. WAL CHECKPOINT — ΚΡΙΣΙΜΟ:
    //    Σε WAL mode, πρόσφατες εγγραφές ζουν στο ξεχωριστό .db-wal αρχείο.
    //    Χωρίς checkpoint, ένα raw copy του .db μπορεί να έχει ΠΑΛΙΑ δεδομένα
    //    (χωρίς error!). Το TRUNCATE "αδειάζει" το WAL μέσα στο κύριο .db.
    await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    
    final archive = Archive();
    
    // 2. Βάση δεδομένων (μετά το checkpoint είναι ΠΛΗΡΗΣ)
    final dbDir = await getApplicationDocumentsDirectory();
    final dbFile = await resolveDatabaseFile();
    if (await dbFile.exists()) {
      archive.addFile(
        ArchiveFile('database/${AppConstants.dbName}', await dbFile.length(),
            await dbFile.readAsBytes()),
      );
    }
    
    // 3. Attachments (φωτογραφίες αποδείξεων)
    final attachmentsDir = Directory(p.join(dbDir.path, 'attachments'));
    if (await attachmentsDir.exists()) {
      await for (final entity in attachmentsDir.list(recursive: true)) {
        if (entity is File) {
          final relPath = p.relative(entity.path, from: dbDir.path);
          archive.addFile(
            ArchiveFile(relPath, await entity.length(), await entity.readAsBytes()),
          );
        }
      }
    }
    
    // 4. Manifest (μεταδεδομένα backup)
    final manifest = '{"version":1,"created":"$timestamp","db":"${AppConstants.dbName}"}';
    archive.addFile(ArchiveFile('manifest.json', manifest.length, manifest.codeUnits));
    
    // Εξαγωγή
    final zipBytes = ZipEncoder().encode(archive);
    return await File(zipPath).writeAsBytes(zipBytes!);
  }
  
  /// Restore: διαβάζει ZIP → αντικαθιστά .db + attachments
  Future<void> restoreFromBackup(String zipPath) async {
    // ΚΡΙΣΙΜΟ: Κλείνουμε τη ζωντανή σύνδεση ΠΡΙΝ αντικαταστήσουμε το αρχείο.
    //   - Στα Windows η αντικατάσταση αποτυγχάνει με open file handle.
    //   - Χωρίς close, η ζωντανή σύνδεση συνεχίζει να βλέπει ΠΑΛΙΑ δεδομένα
    //     από cache μέχρι restart — επικίνδυνο (ο χρήστης βλέπει παλιά data).
    await _db.close();
    
    try {
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final dbDir = await getApplicationDocumentsDirectory();
      
      // Καθαρισμός παλιών WAL/SHM βοηθητικών αρχείων (θα δημιουργηθούν ξανά
      // από τη νέα βάση στο επόμενο άνοιγμα — αλλιώς περιέχουν παλιά δεδομένα).
      final dbFile = await resolveDatabaseFile();
      final dbWal = File('${dbFile.path}-wal');
      final dbShm = File('${dbFile.path}-shm');
      if (await dbWal.exists()) await dbWal.delete();
      if (await dbShm.exists()) await dbShm.delete();
      
      for (final file in archive) {
        final filePath = p.join(dbDir.path, file.name);
        if (file.isFile) {
          await File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        }
      }
      
      // Σημ.: ΔΕΝ ξανανοίγουμε εδώ τη βάση — το κάνει το app startup.
      // Ο UI ενημερώνει: "Η εφαρμογή θα κλείσει μετά την επαναφορά".
    } catch (e) {
      rethrow;
    }
  }
  
  /// Λίστα διαθέσιμων backups
  Future<List<FileSystemEntity>> listBackups() async {
    final dir = await _backupDirectory();
    if (!await dir.exists()) return [];
    return dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.path.compareTo(a.path));
  }
}
```

#### Πολιτική Backup
- **Τιποτικό backup εντός εφαρμογής:** Από το settings → "Δημιουργία backup"
- **Αυτόματο backup:** Προαιρετικό (μελλοντικά, π.χ. κάθε έξοδο εφαρμογής)
- **Restore:** Από settings → "Επαναφορά από backup". Επιβεβαίωση:
  "Η επαναφορά θα αντικαταστήσει όλα τα τρέχοντα δεδομένα και **η εφαρμογή θα κλείσει**"
  → μετά την επιτυχή restore, κλείνει η εφαρμογή (restart φορτώνει το backup)
- **Χρήστης μπορεί να στείλει το .zip στο cloud/SD card μόνος του (share sheet)**
- **Attachments** συμπεριλαμβάνονται ΠΑΝΤΑ στο backup (δεν γίνεται backup χωρίς τις φωτογραφίες)

#### Migration Tests (`test/unit/core/database/`)
- Κάθε `schemaVersion` bump: test με in-memory DB που εκτελεί upgrade v→v+1
- Test ότι η restore δημιουργεί functional DB (query receipt)
- Test ότι οι UUIDs παραμένουν μοναδικοί μετά από restore

---

## 5. Features Layer

### 5.1 Receipt Feature

#### 5.1.1 Entity (`features/receipt/domain/entities/receipt.dart`)

```dart
class Receipt {
  final int? id;
  final String uuid;
  final int receiptNumber;
  final DateTime receiptDate;
  final int supplierId;
  final String? invoiceNumber;
  final String? invoiceSeries;
  final String? paymentMethod;
  final double totalAmount;
  final double vatTotal;
  final double discountTotal;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final String? notes;
  final String? attachmentPath;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Receipt({
    this.id,
    required this.uuid,
    required this.receiptNumber,
    required this.receiptDate,
    required this.supplierId,
    this.invoiceNumber,
    this.invoiceSeries,
    this.paymentMethod,
    this.totalAmount = 0,
    this.vatTotal = 0,
    this.discountTotal = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    this.paymentStatus = 'pending',
    this.notes,
    this.attachmentPath,
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  bool get isPaid => paymentStatus == 'paid';
  bool get isPartial => paymentStatus == 'partial';
  bool get isPending => paymentStatus == 'pending';
  
  Receipt copyWith({
    int? id,
    String? uuid,
    int? receiptNumber,
    DateTime? receiptDate,
    int? supplierId,
    String? invoiceNumber,
    String? invoiceSeries,
    String? paymentMethod,
    double? totalAmount,
    double? vatTotal,
    double? discountTotal,
    double? paidAmount,
    double? remainingAmount,
    String? paymentStatus,
    String? notes,
    String? attachmentPath,
    bool? isSynced,
  }) {
    return Receipt(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptDate: receiptDate ?? this.receiptDate,
      supplierId: supplierId ?? this.supplierId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceSeries: invoiceSeries ?? this.invoiceSeries,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      vatTotal: vatTotal ?? this.vatTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
```

#### 5.1.2 Receipt Item Entity

```dart
class ReceiptItem {
  final int? id;
  final int receiptId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double vatAmount;
  final double discount;
  final double totalPrice;
  final double totalWithVat;
  final String? notes;
  final DateTime createdAt;
  
  const ReceiptItem({
    this.id,
    required this.receiptId,
    required this.itemId,
    this.quantity = 1,
    required this.unitPrice,
    this.vatRate = 24.0,
    this.vatAmount = 0,
    this.discount = 0,
    required this.totalPrice,
    required this.totalWithVat,
    this.notes,
    required this.createdAt,
  });
  
  double get effectiveVatRate => vatRate;
  
  factory ReceiptItem.calculate({
    required int receiptId,
    required int itemId,
    required double quantity,
    required double unitPrice,
    double vatRate = 24.0,
    double discount = 0,
  }) {
    final subtotal = quantity * unitPrice;
    final discountAmount = subtotal * (discount / 100);
    final taxableAmount = subtotal - discountAmount;
    final vatAmount = taxableAmount * (vatRate / 100);
    final totalWithVat = taxableAmount + vatAmount;
    
    return ReceiptItem(
      receiptId: receiptId,
      itemId: itemId,
      quantity: quantity,
      unitPrice: unitPrice,
      vatRate: vatRate,
      vatAmount: vatAmount,
      discount: discount,
      totalPrice: taxableAmount,
      totalWithVat: totalWithVat,
      createdAt: DateTime.now(),
    );
  }
}
```

#### 5.1.3 Input Models (SPoT — `features/receipt/domain/models/receipt_input.dart`)

> **SPoT:** Εδώ ορίζονται ΜΟΝΟ μια φορά τα `ReceiptInput`, `ReceiptItemInput`,
> `PaymentInput` και `ReceiptItemUpdate`. Ta χρησιμοποιούν: ReceiptDao (§4.3),
> abstract Repository (§5.1.4) και το impl (§5.1.5) — μέσω import. ΔΕΝ
> επιτρέπεται δεύτερος ορισμός αλλού (αποφυγή name collision).

```dart
class ReceiptInput {
  final DateTime date;
  final int supplierId;
  final String? invoiceNumber;
  final String? invoiceSeries;
  final String paymentMethod;
  final List<ReceiptItemInput> items;
  final List<PaymentInput> payments;
  final String? notes;
  
  const ReceiptInput({
    required this.date,
    required this.supplierId,
    this.invoiceNumber,
    this.invoiceSeries,
    required this.paymentMethod,
    required this.items,
    this.payments = const [],
    this.notes,
  });
}

class ReceiptItemInput {
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double discount;
  
  const ReceiptItemInput({
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    this.vatRate = AppConstants.defaultVatRate, // SPoT: όχι literal 24.0
    this.discount = 0,
  });
}

class PaymentInput {
  final double amount;
  final DateTime date;
  final String method;
  final String? reference;
  
  const PaymentInput({
    required this.amount,
    required this.date,
    required this.method,
    this.reference,
  });
}

class ReceiptItemUpdate {
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double discount;
  
  const ReceiptItemUpdate({
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.discount,
  });
}
```

> **✅ Υλοποιήθηκε — Phase 3 Step 1 (11/09/2026):** τα 4 classes SPoT δημιουργήθηκαν
> στο `features/receipt/domain/models/receipt_input.dart` (~102 γρ., <500), με το
> σχέδιο του §5.1.3 ως έχει. Αποφάσεις υλοποίησης: `vatRate` default =
> `AppConstants.defaultVatRate` (SPoT, ΟΧΙ literal 24.0)· `items` required, `payments`
> default `const []`· καθόλου `==`/`hashCode`/`copyWith`/validation (pure carriers).
> Τα columns `receipt_items.notes` & `payments.notes` ΔΕΝ εκτίθενται στα input
> models. Το `ReceiptItemInput` placeholder του `validators.dart` παραμένει μέχρι το
> Βήμα 5 (αντικατάσταση σε `validators.dart` + `validators_test.dart` = ξεχωριστή
> έγκριση). Tests: `test/unit/features/receipt/domain/models/receipt_input_test.dart`
> (12 tests) → **257/257, analyze clean**.

#### 5.1.4 Repository (Abstract)

```dart
/// SPO: ReceiptRepository - reactive (Stream) για δεδομένα που αλλάζουν συχνά,
/// Future για single-shot λειτουργίες (create/delete/update).
abstract class ReceiptRepository {
  Stream<List<Receipt>> watchAll({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    String? paymentStatus,
  });
  
  Future<Receipt?> getById(int id);
  
  Stream<List<ReceiptItem>> watchItemsByReceiptId(int receiptId);
  
  Future<int> create(ReceiptInput input);
  
  Future<void> updateItem(int receiptId, int itemId, ReceiptItemUpdate update);
  
  Future<void> deleteItem(int receiptId, int itemId);
  
  Future<void> delete(int id);
  
  Future<int> getNextReceiptNumber();
  
  Stream<double> watchTotalByDateRange(DateTime start, DateTime end);
  
  Stream<Map<String, double>> watchTotalByCategory(DateTime start, DateTime end);
}
```

#### 5.1.5 Repository (Implementation)

```dart
class ReceiptRepositoryImpl implements ReceiptRepository {
  final ReceiptDao _receiptDao;
  
  ReceiptRepositoryImpl(this._receiptDao);
  
  @override
  Stream<List<Receipt>> watchAll({
    DateTime? startDate,
    DateTime? endDate,
    int? supplierId,
    String? paymentStatus,
  }) {
    return _receiptDao.watchAllReceipts(
      startDate: startDate,
      endDate: endDate,
      supplierId: supplierId,
      paymentStatus: paymentStatus,
    );
  }
  
  @override
  Future<Receipt?> getById(int id) async {
    return _receiptDao.getReceiptById(id);
  }
  
  @override
  Stream<List<ReceiptItem>> watchItemsByReceiptId(int receiptId) {
    return _receiptDao.watchReceiptItems(receiptId);
  }
  
  @override
  Future<int> create(ReceiptInput input) async {
    return _receiptDao.createReceipt(input);
  }
  
  @override
  Future<int> getNextReceiptNumber() async {
    return _receiptDao.getNextReceiptNumber();
  }
  
  @override
  Future<void> updateItem(int receiptId, int itemId, ReceiptItemUpdate update) async {
    await _receiptDao.updateReceiptItem(receiptId, itemId, update);
  }
  
  @override
  Future<void> deleteItem(int receiptId, int itemId) async {
    await _receiptDao.deleteReceiptItem(receiptId, itemId);
  }
  
  @override
  Future<void> delete(int id) async {
    await _receiptDao.deleteReceipt(id);
  }
  
  @override
  Stream<double> watchTotalByDateRange(DateTime start, DateTime end) {
    // Live aggregate query - no stored column
    return _receiptDao.watchTotalByDateRange(start, end);
  }
  
  @override
  Stream<Map<String, double>> watchTotalByCategory(DateTime start, DateTime end) {
    // Live aggregate query - no stored column
    return _receiptDao.watchTotalByCategory(start, end);
  }
}
```

#### 5.1.6 Live Aggregate Queries (No Stored Columns)

```dart
// SPO: Live aggregate queries - always fresh data
// Αυτό λύνει το πρόβλημα των stored columns που μπορεί να μείνουν stale
// Σημ.: τα όρια start/end μετατρέπονται σε UTC πριν φτάσουν στη βάση,
// γιατί η βάση αποθηκεύει UTC (UtcDateTimeConverter) — αλλιώς το
// customSelect συγκρίνει local με UTC κι επιστρέφει λάθος εύρος.

extension ReceiptDaoAggregates on ReceiptDao {
  /// Watch total amount for date range (reactive)
  /// total_amount = Σ καθαρών (πριν ΦΠΑ), vat_total = ΦΠΑ.
  /// Το σύνολο που βλέπει ο χρήστης = μεικτό (συμπεριλαμβανομένου ΦΠΑ),
  /// συνεπές με το watchTotalByCategory (και τα δύο gross).
  Stream<double> watchTotalByDateRange(DateTime start, DateTime end) {
    final query = customSelect(
      'SELECT COALESCE(SUM(total_amount + vat_total), 0) as total '
      'FROM receipts '
      'WHERE receipt_date >= ? AND receipt_date <= ?',
      variables: [
        Variable.withDateTime(start.toUtc()),
        Variable.withDateTime(end.toUtc()),
      ],
      readsFrom: {receipts},
    );
    
    return query.watch().map((rows) => rows.first.read<double>('total') ?? 0);
  }
  
  /// Watch totals by category (reactive)
  Stream<Map<String, double>> watchTotalByCategory(DateTime start, DateTime end) {
    final query = customSelect(
      'SELECT c.name as category_name, '
      'COALESCE(SUM(ri.total_with_vat), 0) as total '
      'FROM receipt_items ri '
      'JOIN items i ON ri.item_id = i.id '
      'JOIN categories c ON i.category_id = c.id '
      'JOIN receipts r ON ri.receipt_id = r.id '
      'WHERE r.receipt_date >= ? AND r.receipt_date <= ? '
      'GROUP BY c.id '
      'ORDER BY total DESC',
      variables: [
        Variable.withDateTime(start.toUtc()),
        Variable.withDateTime(end.toUtc()),
      ],
      readsFrom: {receiptItems, items, categories, receipts},
    );
    
    return query.watch().map((rows) {
      return {
        for (var row in rows)
          row.read<String>('category_name'): row.read<double>('total') ?? 0,
      };
    });
  }
  
  /// Watch receipt count (reactive)
  Stream<int> watchReceiptCount() {
    final query = customSelect(
      'SELECT COUNT(*) as count FROM receipts',
      readsFrom: {receipts},
    );
    
    return query.watch().map((rows) => rows.first.read<int>('count') ?? 0);
  }
  
  /// Watch average receipt amount (reactive)
  Stream<double> watchAverageAmount() {
    final query = customSelect(
      'SELECT COALESCE(AVG(total_amount), 0) as average FROM receipts',
    );
    
    return query.watch().map((rows) => rows.first.read<double>('average') ?? 0);
  }
}
```

### 5.2 Repositories (Phase 2 Step 4 — Route A-Συνεπές, 10/09/2026)

**Απόκλιση:** Η πλήρης Clean-Architecture (entities/models/datasources/usecases/presentation
ανά feature) δημιουργείται μαζί με κάθε feature (Phase 3–6). Τώρα δημιουργήθηκαν
ΜΟΝΟ τα repositories (abstract + impl) για τα 4 features που έχουν DAO.
Δεν δημιουργήθηκαν domain entities — τα drift DataClasses (`Item`, `Category`,
`Supplier`, `Budget`) είναι τα current SPoT entities (immutable + `==`/`hashCode`).
`injection/dependency_injection.dart` υλοποιήθηκε πρόωρα στο Phase 2 Step 4.2 (απόκλιση
από §5.2 που προέβλεπε Phase 3). ReceiptRepository αναβάλλεται πλήρως στο Phase 3
(μαζί με ReceiptDao + §5.1.4/§5.1.5).

**Abstract contracts** (`features/<f>/domain/repositories/<f>_repository.dart`):

| Feature | Methods (reactive / single-shot) |
|---|---|
| ItemRepository | `watchAll`, `watchByCategory`, `watchByBarcode`, `searchByName`, `watchLowStock`, `getById`, `create`, `update`, `softDelete`, `increaseStock` (10) |
| CategoryRepository | `watchAll`, `watchTree`, `watchWithChildrenRecursively`, `getById`, `create` ← throws `CategoryDuplicateNameException`, `update`, `softDelete` (7) |
| SupplierRepository | `watchAll`, `searchByName`, `getById`, `create`, `update`, `softDelete`, `getReceiptCount` (7) |
| BudgetRepository | `watchBudget`, `watchBudgetsForMonth`, `upsertBudget`, `watchDashboardSpending` (4) |

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

## 6. Responsive Design System

### 6.1 Screen Layouts

#### Mobile (< 600px)
```
┌─────────────────┐
│   App Bar       │
├─────────────────┤
│                 │
│   Content       │
│   (Full Width)  │
│                 │
├─────────────────┤
│  Bottom Nav Bar │
└─────────────────┘
```

#### Tablet (600px - 1200px)
```
┌─────────────────────────────────────┐
│           App Bar                   │
├─────────────────────────────────────┤
│           │                         │
│  Side     │      Content            │
│  Nav      │      (2 Columns)        │
│  Rail     │                         │
│           │                         │
└─────────────────────────────────────┘
```

#### Desktop (> 1200px)
```
┌─────────────────────────────────────────────────────┐
│                    App Bar                          │
├────────────────┬────────────────────────────────────┤
│                │                                    │
│  Navigation    │         Content                    │
│  Drawer        │         (3-4 Columns)              │
│                │                                    │
│                │                                    │
└────────────────┴────────────────────────────────────┘
```

### 6.2 Navigation Strategy

```dart
/// SPO: Navigation based on screen size
class AppNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileNavigation(context),
      tablet: _buildTabletNavigation(context),
      desktop: _buildDesktopNavigation(context),
    );
  }
  
  Widget _buildMobileNavigation(BuildContext context) {
    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Αρχική'),
          NavigationDestination(icon: Icon(Icons.receipt), label: 'Αποδείξεις'),
          NavigationDestination(icon: Icon(Icons.category), label: 'Είδη'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Αναφορές'),
        ],
      ),
    );
  }
  
  Widget _buildTabletNavigation(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.selected,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.home), label: Text('Αρχική')),
              NavigationRailDestination(icon: Icon(Icons.receipt), label: Text('Αποδείξεις')),
              NavigationRailDestination(icon: Icon(Icons.category), label: Text('Είδη')),
              NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Αναφορές')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _currentScreen),
        ],
      ),
    );
  }
  
  Widget _buildDesktopNavigation(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
                child: Text('ExpenseTracker', style: TextStyle(fontSize: 20)),
              ),
              NavigationDrawerDestination(icon: Icon(Icons.home), label: Text('Αρχική')),
              NavigationDrawerDestination(icon: Icon(Icons.receipt), label: Text('Αποδείξεις')),
              NavigationDrawerDestination(icon: Icon(Icons.category), label: Text('Είδη')),
              NavigationDrawerDestination(icon: Icon(Icons.bar_chart), label: Text('Αναφορές')),
              Divider(),
              NavigationDrawerDestination(icon: Icon(Icons.settings), label: Text('Ρυθμίσεις')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _currentScreen),
        ],
      ),
    );
  }
}
```

### 6.3 Responsive Grid

```dart
/// SPO: Responsive grid widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = Breakpoints.gridColumns(context);
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: columns == 1 ? 2 : 1.5,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
```

---

## 7. Theme System (Dark/Light)

> **ΣΗΜΕΙΩΣΗ:** Τα snippets του §7 είναι pre-implementation drafts (τιμές
> χρωμάτων/διαστάσεων/τυπογραφίας διαφέρουν). Πηγή αλήθειας: §3.11–§3.13 +
> `lib/core/theme/` (νέα πεδία: `AppColors.overlay/divider*`,
> `AppDimensions.desktopLarge/suggestionListMaxHeight/iconXxl`,
> `AppTheme` με `CardThemeData` + `AppDimensions`).

### 7.1 Color Palette

```dart
/// SPO: Color palette
class AppColors {
  AppColors._();
  
  // Primary Colors
  static const Color primaryLight = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF90CAF9);
  
  // Secondary Colors
  static const Color secondaryLight = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF81C784);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
  
  // Payment Status Colors
  static const Color paid = Color(0xFF4CAF50);
  static const Color partial = Color(0xFFFFA726);
  static const Color pending = Color(0xFFE53935);
  
  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];
  
  // Light Theme Background
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  
  // Dark Theme Background
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
}
```

### 7.2 Text Styles

```dart
/// SPO: Typography
class AppTextStyles {
  AppTextStyles._();
  
  static TextStyle headline1(BuildContext context) => 
    Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontWeight: FontWeight.bold,
    );
  
  static TextStyle headline2(BuildContext context) => 
    Theme.of(context).textTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.bold,
    );
  
  static TextStyle headline3(BuildContext context) => 
    Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
    );
  
  static TextStyle bodyText1(BuildContext context) => 
    Theme.of(context).textTheme.bodyLarge!;
  
  static TextStyle bodyText2(BuildContext context) => 
    Theme.of(context).textTheme.bodyMedium!;
  
  static TextStyle caption(BuildContext context) => 
    Theme.of(context).textTheme.bodySmall!;
  
  static TextStyle buttonText(BuildContext context) => 
    Theme.of(context).textTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.w600,
    );
}
```

### 7.3 Dimensions

```dart
/// SPO: Spacing and sizing constants
class AppDimensions {
  AppDimensions._();
  
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  
  // Border Radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusFull = 9999;
  
  // Card Elevation
  static const double elevationSm = 1;
  static const double elevationMd = 2;
  static const double elevationLg = 4;
  
  // Icon Sizes
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  
  // Button Heights
  static const double buttonHeight = 48;
  static const double buttonHeightSm = 36;
  
  // App Bar Height
  static const double appBarHeight = 56;
  
  // Bottom Nav Height
  static const double bottomNavHeight = 80;
  
  // Navigation Rail Width
  static const double navigationRailWidth = 80;
  
  // Navigation Drawer Width
  static const double navigationDrawerWidth = 280;
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

| Component | Test File | Coverage |
|---|---|---|
| CurrencyFormatter | `test/unit/core/utils/currency_formatter_test.dart` | 100% |
| DateFormatter | `test/unit/core/utils/date_formatter_test.dart` | 100% |
| Validators | `test/unit/core/utils/validators_test.dart` | 100% |
| ReceiptRepository | `test/unit/features/receipt/data/repositories/receipt_repository_test.dart` | 90% |
| Receipt UseCases | `test/unit/features/receipt/domain/usecases/` | 90% |
| ReceiptInput models | `test/unit/features/receipt/domain/models/receipt_input_test.dart` | 12 tests ✅ 11/09/2026 |
| ItemRepository | `test/unit/features/item/data/repositories/item_repository_test.dart` | 90% |
| BudgetService | `test/unit/features/budget/domain/usecases/` | 90% |
| MigrationHelper | `test/unit/core/database/migrations/migration_test.dart` | 95% |
| BackupService | `test/unit/core/database/backup/backup_service_test.dart` | 90% |
| ItemRepositoryImpl | `test/unit/features/item/data/repositories/item_repository_impl_test.dart` | 90% |
| CategoryRepositoryImpl | `test/unit/features/category/data/repositories/category_repository_impl_test.dart` | 90% |
| SupplierRepositoryImpl | `test/unit/features/supplier/data/repositories/supplier_repository_impl_test.dart` | 90% |
| BudgetRepositoryImpl | `test/unit/features/budget/data/repositories/budget_repository_impl_test.dart` | 90% |
| ThemeProvider (SettingDao-backed) | `test/unit/core/theme/theme_provider_test.dart` | 95% |
| DependencyInjection | `test/unit/injection/dependency_injection_test.dart` | 100% |

### 8.2 Widget Tests

| Widget | Test File | Coverage |
|---|---|---|
| ResponsiveLayout | `test/widget/core/widgets/responsive_layout_test.dart` | 100% |
| AutoSuggestField | `test/widget/core/widgets/auto_suggest_field_test.dart` | 90% |
| ReceiptForm | `test/widget/features/receipt/presentation/widgets/receipt_form_test.dart` | 85% |
| ReceiptCard | `test/widget/features/receipt/presentation/widgets/receipt_card_test.dart` | 85% |
| CategoryChart | `test/widget/features/reports/presentation/widgets/category_chart_test.dart` | 80% |
| BudgetProgress | `test/widget/features/budget/presentation/widgets/budget_progress_test.dart` | 80% |

### 8.3 Integration Tests

| Flow | Test File | Steps |
|---|---|---|
| Receipt Entry | `test/integration/receipt_entry_flow_test.dart` | Create → Add Items → Save → Verify |
| Budget Tracking | `test/integration/budget_tracking_flow_test.dart` | Set Budget → Add Receipt → Check Spent |
| Report Generation | `test/integration/report_generation_flow_test.dart` | Select Date → Generate → Export |

### 8.4 Edge Case Tests

```dart
// Test File: test/unit/core/utils/validators_edge_cases_test.dart
void main() {
  group('Validators Edge Cases', () {
    test('validateQuantity should reject zero', () {
      expect(Validators.validateQuantity('0'), isNotNull);
    });
    
    test('validateQuantity should reject negative', () {
      expect(Validators.validateQuantity('-5'), isNotNull);
    });
    
    test('validateQuantity should reject very large numbers', () {
      expect(Validators.validateQuantity('999999'), isNotNull);
    });
    
    test('validatePrice should accept zero', () {
      expect(Validators.validatePrice('0'), isNull);
    });
    
    test('validatePrice should reject negative', () {
      expect(Validators.validatePrice('-10'), isNotNull);
    });
    
    test('validateItemName should handle special characters', () {
      expect(Validators.validateItemName('Test@#$%'), isNull);
    });
    
    test('validateItemName should handle very long strings', () {
      expect(Validators.validateItemName('A' * 101), isNotNull);
    });
  });
}
```

---

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
> Σειρά εκτέλεσης βημάτων: 2) ReceiptDao, 3) codegen + DAO tests, 4) ReceiptRepository
> abstract+impl + DI, 5) αντικατάσταση placeholder `validators.dart`, 6) BLoC,
> 7) presentation, 8) sync .md.

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

## 📋 Checklist Υλοποίησης

- [ ] Phase 1: Project Setup
- [x] Phase 2: Database Layer
- [ ] Phase 3: Receipt Feature (Step 1 ✅ — Input models SPoT, 11/09/2026)
- [ ] Phase 4: Item & Category Features
- [ ] Phase 5: Supplier Feature
- [ ] Phase 6: Budget Feature
- [ ] Phase 7: Reports & Analytics
- [ ] Phase 8: Dashboard
- [ ] Phase 9: Navigation & Polish
- [ ] Phase 10: Testing
- [ ] Phase 11: Polish & Deployment

---

*Τελευταία ενημέρωση: 2026-09-11 | Με Drift (αντί sqflite/floor)*
