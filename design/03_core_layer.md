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

> **⚠️ STALE (11/09/2026 — Βήμα 5):** Το παρακάτω snippet ήταν πριν το Βήμα 5
> (αντικατάσταση placeholder + per-item checks). Η πραγματική υλοποίηση τώρα:
> import `receipt_input.dart` (ReceiptItemInput SPoT), `AppConstants.maxQuantity`/
> `maxPrice`/`maxDiscountPercent` αντί magic literals, `!item.quantity.isFinite`
> (NaN+Infinity), per-item loop (5 checks) με prefix "Είδος N:", `AppStrings`
> παντού. Η δομή παραμένει η ίδια (validators → ValidationResult) αλλά ο
> κώδικας είναι πολύ διαφορετικός — αναφορά στο πραγματικό αρχείο.

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

