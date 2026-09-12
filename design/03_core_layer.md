## 3. Core Layer (SPOs & Utilities)

> **Σημείωση (12/09/2026):** Το αρχείο χωρίστηκε σε 3 (κανόνας ≤500 γρ.):
> - `03_core_layer.md` → §3.1–3.7 (constants, strings, debug, formatters)
> - `03_utilities_widgets.md` → §3.8–3.10 (validators, responsive, auto-suggest)
> - `03_theme_extensions.md` → §3.11–3.13 (theme, theme provider, extensions)

### 3.1 App Constants (`core/constants/app_constants.dart`)

> **Ενημέρωση (Phase 3 Βήμα 5):** προστέθηκαν `maxQuantity`, `maxPrice`,
> `maxDiscountPercent`. **Ενημέρωση (SPoT Status Pattern 12/09/2026):**
> τα `paymentStatus*` είναι `static const String` — ΠΡΕΠΕΙ να μείνουν const
> γιατί το `.g.dart` κάνει `const Constant(AppConstants.paymentStatusPending)`
> (compile-time). Το νέο enum `ReceiptPaymentStatus` (ίδιο folder, §ενότητα
> εδώ κάτω) «καταναλώνει» τα constants — ΠοΤΕ αντίστροφα.

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

### 3.1b Receipt Payment Status — SPoT Status Pattern (`core/constants/receipt_payment_status.dart`)

> **Νέο (12/09/2026):** type-safe layer πάνω στα `paymentStatus*` constants.
> Τα members «καταναλώνουν» τα const strings (SPoT για `.g.dart` @3166).
> Το drift DataClass `Receipt.paymentStatus` παραμένει **String** (schema) —
> η μετατροπή γίνεται στα boundaries με `fromDbValue` (DAO `_paymentStatus`,
> repository filters, BLoC event, chip). ΑΥΣΤΗΡΟ fail-fast: άγνωστη τιμή →
> `ArgumentError` + `AppLogger.error` (single-writer: μόνο ο DAO γράφει).

```dart
enum ReceiptPaymentStatus {
  pending(AppConstants.paymentStatusPending),
  partial(AppConstants.paymentStatusPartial),
  paid(AppConstants.paymentStatusPaid);

  const ReceiptPaymentStatus(this.dbValue);

  /// Αποθηκευμένη τιμή DB ('pending' | 'partial' | 'paid').
  final String dbValue;

  static ReceiptPaymentStatus fromDbValue(String value) {
    for (final status in values) {
      if (status.dbValue == value) return status;
    }
    if (DebugConfig.isDebug) {
      AppLogger.error('ReceiptPaymentStatus: άγνωστη τιμή "$value"');
    }
    throw ArgumentError.value(value, 'dbValue',
        'Άγνωστο ReceiptPaymentStatus (pending/partial/paid)');
  }
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