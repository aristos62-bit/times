/// SPoT validator απόδειξης — γραμμές («καλάθι») και κεφαλίδα
/// (§2.2 «Validation πριν την αποθήκευση» DESIGN · Φάση 3 Βήμα 6β).
///
/// Ίδιο contract με τον `NameValidator` (απόφαση Βήμα 4): κάθε μέθοδος
/// επιστρέφει `null` όταν η τιμή είναι αποδεκτή ή το SPoT μήνυμα
/// (`AppErrors` / `AppMessages`) που δείχνει το UI. ΚΑΝΕΝΑ exception.
///
/// Καθαρός και σύγχρονος: δεν διαβάζει UI/DB/theme, δεν κάνει logging και
/// δεν εξαρτάται από presentation/data (δουλεύει με primitives) — το
/// logging και το feedback ανήκουν στον καλούντα (controller/widget).
///
/// Οι κανόνες προέρχονται αποκλειστικά από το `AppConstants`:
///   * τιμή (σε ΛΕΠΤΑ, §3): `> validationMinPrice` και `<= maxPriceCents`,
///   * έκπτωση μονάδας (σε ΛΕΠΤΑ, §2.2): `0 ≤ discountCents ≤ priceCents`,
///   * ποσότητα: `> validationMinQuantity` και `<= maxQuantity`,
///   * ακέραια ποσότητα όταν `Unit.allowsDecimal == false` (§2.2:218),
///   * γραμμές απόδειξης: `1 .. maxReceiptLines`.
///
/// Δεν υπολογίζει `lineTotalCents` — ο υπολογισμός είναι SPoT του
/// `ReceiptLineDao` (§3).
library;

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_errors.dart';
import '../../core/constants/app_messages.dart';

/// SPoT namespace — μόνο static, δεν instantiate (pattern AppConstants).
abstract final class ReceiptValidator {
  /// Η γραμμή χρειάζεται μονάδα μέτρησης: [hasUnit] false → `unitRequired`.
  static String? validateUnit(bool hasUnit) =>
      hasUnit ? null : AppErrors.unitRequired;

  /// Τιμή σε λεπτά (priceCents, §3): `<= validationMinPrice` →
  /// `priceMustBePositive` · `> maxPriceCents` → `priceTooLarge` · αλλιώς `null`.
  static String? validatePriceCents(int priceCents) {
    if (priceCents <= AppConstants.validationMinPrice) {
      return AppErrors.priceMustBePositive;
    }
    if (priceCents > AppConstants.maxPriceCents) {
      return AppErrors.priceTooLarge;
    }
    return null;
  }

  /// Έκπτωση μονάδας σε λεπτά (§2.2): `< 0` (defensive, programmatic-only —
  /// το UI regex αποκλείει το «−», `CurrencyTextField.parseCents`) →
  /// `discountNegative` · `> priceCents` → `discountTooLarge` · αλλιώς `null`
  /// (το `0` = καμία έκπτωση ΕΙΝΑΙ έγκυρο — δεν μεταφέρεται το
  /// Positive-pattern των ορίων).
  static String? validateDiscountCents(int discountCents, int priceCents) {
    if (discountCents < 0) {
      return AppErrors.discountNegative;
    }
    if (discountCents > priceCents) {
      return AppErrors.discountTooLarge;
    }
    return null;
  }

  /// Ποσότητα: `NaN` ή `<= validationMinQuantity` → `quantityMustBePositive` ·
  /// `> maxQuantity` → `quantityTooLarge` · δεκαδική τιμή ενώ
  /// [allowsDecimal] false → `quantityMustBeInteger` (§2.2:218) · αλλιώς `null`.
  ///
  /// Η σειρά είναι σταθερή (θετική → όριο → ακέραια): το «0» σε μονάδα χωρίς
  /// κλάσματα δίνει `quantityMustBePositive`, όχι `quantityMustBeInteger`.
  static String? validateQuantity(
      double quantity, {
        required bool allowsDecimal,
      }) {
    if (quantity.isNaN || quantity <= AppConstants.validationMinQuantity) {
      return AppErrors.quantityMustBePositive;
    }
    if (quantity > AppConstants.maxQuantity) {
      return AppErrors.quantityTooLarge;
    }
    if (!allowsDecimal && quantity != quantity.truncateToDouble()) {
      return AppErrors.quantityMustBeInteger;
    }
    return null;
  }

  /// Ολόκληρη γραμμή: επιστρέφει το ΠΡΩΤΟ σφάλμα (ποσότητα, μετά τιμή,
  /// μετά έκπτωση — η έκπτωση αναφέρεται στην τιμή) ή `null`.
  static String? validateLine({
    required double quantity,
    required int priceCents,
    int discountCents = 0,
    required bool allowsDecimal,
  }) =>
      validateQuantity(quantity, allowsDecimal: allowsDecimal) ??
          validatePriceCents(priceCents) ??
          validateDiscountCents(discountCents, priceCents);

  /// Πλήθος γραμμών «καλαθιού»: `< 1` → `receiptLinesRequired` ·
  /// `> maxReceiptLines` → `AppMessages.receiptLinesLimitReached` (ίδιο κείμενο
  /// με το inline μήνυμα του section, χωρίς διπλό string) · αλλιώς `null`.
  static String? validateLineCount(int count) {
    if (count < 1) return AppErrors.receiptLinesRequired;
    if (count > AppConstants.maxReceiptLines) {
      return AppMessages.receiptLinesLimitReached(
        AppConstants.maxReceiptLines,
      );
    }
    return null;
  }

  /// Κεφαλίδα + πλήθος γραμμών (κανόνας του disabled-OR στο κουμπί
  /// αποθήκευσης και του safety-net στο `saveReceipt`): πρώτα οι γραμμές,
  /// μετά ο προμηθευτής ([hasSupplier] false → `supplierRequired`).
  static String? validateReceipt({
    required bool hasSupplier,
    required int lineCount,
  }) =>
      validateLineCount(lineCount) ??
          (hasSupplier ? null : AppErrors.supplierRequired);

  /// True όταν το [text] είναι αριθμός «υπό πληκτρολόγηση» (τελειώνει σε
  /// διαχωριστή `.` ή `,`, π.χ. «5,»). Το UI δεν δείχνει σφάλμα σε τέτοια
  /// είσοδο, ώστε να μην «αναβοσβήνει» μήνυμα ενώ ο χρήστης γράφει.
  static bool isIncompleteNumber(String text) {
    final trimmed = text.trim();
    return trimmed.endsWith('.') || trimmed.endsWith(',');
  }
}