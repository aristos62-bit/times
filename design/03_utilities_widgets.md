## 3.8 Validators (`core/utils/validators.dart`)

> **⚠️ STALE (11/09/2026 — Βήμα 5):** Το παρακάτω snippet ήταν πριν το Βήμα 5
> (αντικατάσταση placeholder + per-item checks). Η πραγματική υλοποίηση τώρα
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