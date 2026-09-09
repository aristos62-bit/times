import '../constants/app_constants.dart';
import '../strings/app_strings.dart';
import 'currency_formatter.dart';
import 'extensions.dart';

// core/utils/validators.dart
/// SPoT: Input validation - single source of truth
/// Μηνύματα: core/strings/app_strings.dart (AppStrings)

class Validators {
  Validators._();
  
  // Receipt Validators
  static String? validateReceiptDate(DateTime? date) {
    if (date == null) return AppStrings.receiptDateRequired;
    // Edge: +1 λεπτό ανοχή — το DateTime.now() ως είσοδος δεν κρίνεται future από τα ms
    if (date.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      return AppStrings.receiptDateInFuture;
    }
    if (date.isBefore(DateTime(2000))) return AppStrings.invalidDate;
    return null;
  }
  
  static String? validateSupplierId(int? supplierId) {
    if (supplierId == null || supplierId <= 0) return AppStrings.supplierRequired;
    return null;
  }
  
  static String? validatePaymentMethod(String? method) {
    if (method == null || method.isEmpty) return AppStrings.paymentMethodRequired;
    return null;
  }
  
  // Item Validators
  static String? validateItemName(String? name) {
    if (name == null || name.trim().isEmpty) return AppStrings.itemNameRequired;
    if (name.trim().length < 2) return AppStrings.nameTooShort;
    if (name.length > 100) return AppStrings.itemNameTooLong;
    return null;
  }
  
  static String? validateQuantity(String? quantity) {
    if (quantity == null || quantity.isEmpty) return AppStrings.quantityRequired;
    // Reuse: ελληνικό κόμμα/κενά μέσω CurrencyFormatter.tryParse
    final parsed = CurrencyFormatter.tryParse(quantity);
    if (parsed == null) return AppStrings.invalidNumber;
    if (parsed <= 0) return AppStrings.quantityMustBePositive;
    if (parsed > 99999) return AppStrings.quantityTooLarge;
    return null;
  }
  
  static String? validatePrice(String? price) {
    if (price == null || price.isEmpty) return AppStrings.priceRequired;
    // Reuse: ελληνικό κόμμα/κενά μέσω CurrencyFormatter.tryParse
    final parsed = CurrencyFormatter.tryParse(price);
    if (parsed == null) return AppStrings.invalidNumber;
    if (parsed < 0) return AppStrings.priceNegative;
    if (parsed > 999999) return AppStrings.priceTooLarge;
    return null;
  }
  
  static String? validateVatRate(String? rate) {
    if (rate == null || rate.isEmpty) return AppStrings.vatRateRequired;
    // Edge: δεκτό και ελληνικό κόμμα — ΟΧΙ CurrencyFormatter (σβήνει την τελεία).
    // Reuse: DoubleExtensions.approximates αντί contains (double precision).
    final parsed = double.tryParse(rate.replaceAll(',', '.'));
    if (parsed == null) return AppStrings.invalidVatRate;
    if (!AppConstants.vatRates.any((v) => v.approximates(parsed))) {
      return AppStrings.invalidVatRateValue;
    }
    return null;
  }
  
  // Category Validators
  static String? validateCategoryName(String? name) {
    if (name == null || name.trim().isEmpty) return AppStrings.categoryNameRequired;
    if (name.trim().length < 2) return AppStrings.nameTooShort;
    if (name.length > 50) return AppStrings.categoryNameTooLong;
    return null;
  }
  
  // Supplier Validators
  static String? validateSupplierName(String? name) {
    if (name == null || name.trim().isEmpty) return AppStrings.supplierNameRequired;
    if (name.trim().length < 2) return AppStrings.nameTooShort;
    return null;
  }
  
  static String? validateVatNumber(String? vat) {
    if (vat == null || vat.isEmpty) return null; // Optional
    // Edge: το 'EL' αφαιρείται μόνο ως prefix (όχι παντού — το '12EL3456789' είναι άκυρο)
    var cleaned = vat.trim().toUpperCase();
    if (cleaned.startsWith('EL')) cleaned = cleaned.substring(2);
    cleaned = cleaned.replaceAll('-', '').replaceAll(' ', '');
    // Το ελληνικό ΑΦΜ είναι 9 ψηφία χωρίς πρόθεμα EL
    // (το EL χρησιμοποιείται μόνο σε ενδοκοινοτικό VIES format, δεν το αποθηκεύουμε)
    if (!RegExp(r'^\d{9}$').hasMatch(cleaned)) return AppStrings.invalidVatNumber;
    return null;
  }
  
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) return null; // Optional
    final cleaned = phone.replaceAll(' ', '').replaceAll('-', '');
    if (!RegExp(r'^(\+30|0030)?[0-9]{10}$').hasMatch(cleaned)) return AppStrings.invalidPhoneNumber;
    return null;
  }
  
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return null; // Optional
    // Edge: TLD {2,} — δεκτά .travel/.museum (όχι πλήρης RFC, σκόπιμα χαλαρό)
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email)) return AppStrings.invalidEmail;
    return null;
  }
  
  // Budget Validators
  static String? validateBudgetAmount(String? amount) {
    if (amount == null || amount.isEmpty) return AppStrings.budgetAmountRequired;
    // Reuse: ελληνικό κόμμα/κενά μέσω CurrencyFormatter.tryParse
    final parsed = CurrencyFormatter.tryParse(amount);
    if (parsed == null) return AppStrings.invalidNumber;
    if (parsed <= 0) return AppStrings.budgetAmountMustBePositive;
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
      errors.add(AppStrings.receiptMustHaveItems);
    }
    
    // Edge Case: Αρνητικές τιμές
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.quantity <= 0) errors.add('${AppStrings.receiptItemPrefix} ${i + 1}: ${AppStrings.receiptItemInvalidQuantity}');
      if (item.unitPrice < 0) errors.add('${AppStrings.receiptItemPrefix} ${i + 1}: ${AppStrings.receiptItemNegativePrice}');
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

/// SPoT: Receipt item input for batch validation
class ReceiptItemInput {
  final double quantity;
  final double unitPrice;
  
  const ReceiptItemInput({
    required this.quantity,
    required this.unitPrice,
  });
}

/// SPoT: Validation result model
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
  
  String get errorMessage => errors.join('\n');
}
