import '../constants/app_constants.dart';

// core/utils/validators.dart
/// SPoT: Input validation - single source of truth
/// Μηνύματα: core/strings/app_strings.dart (AppStrings)

class Validators {
  Validators._();
  
  // Receipt Validators
  static String? validateReceiptDate(DateTime? date) {
    if (date == null) return 'Επιλέξτε ημερομηνία';
    if (date.isAfter(DateTime.now())) return 'Η ημερομηνία δεν μπορεί να είναι στο μέλλον';
    if (date.isBefore(DateTime(2000))) return 'Μη έγκυρη ημερομηνία';
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

/// SPO: Receipt item input for batch validation
class ReceiptItemInput {
  final double quantity;
  final double unitPrice;
  
  const ReceiptItemInput({
    required this.quantity,
    required this.unitPrice,
  });
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
