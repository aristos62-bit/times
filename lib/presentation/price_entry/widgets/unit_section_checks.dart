/// Part του `unit_quantity_price_section.dart` — helpers ανάγνωσης και
/// validation των πεδίων γραμμής (ποσότητα/τιμή/έκπτωση).
///
/// Μεταφέρθηκε εδώ για τον κανόνα 7 (<500 γρ. — precedent
/// `searchable_dropdown_entry.dart`, κεφ. 21): top-level συναρτήσεις με ρητά
/// ορίσματα (τα class members δεν «συνεχίζονται» σε part). Καθαρές (χωρίς
/// state), ίδια contracts με πριν — κανένα behavior δεν άλλαξε.
part of 'unit_quantity_price_section.dart';

/// Ποσότητα του πεδίου (Βήμα 6δ): `value` = η τιμή ΜΟΝΟ όταν είναι έγκυρη
/// (`ReceiptValidator.validateQuantity`, §2.2:217-218), `error` = inline
/// μήνυμα (AppErrors) ή `null`. Κενό πεδίο και αριθμός «υπό πληκτρολόγηση»
/// («2,») δεν δείχνουν σφάλμα. Το parse γίνεται πάντα με δεκαδικά — ο
/// κανόνας ακεραιότητας ανήκει στον validator. `null` από το parse σε
/// μη-κενό, ολοκληρωμένο κείμενο σημαίνει πάνω από το όριο.
({double? value, String? error}) _quantityCheck(
  TextEditingController controller, {
  required bool allowsDecimal,
}) {
  final text = controller.text;
  if (text.trim().isEmpty) return (value: null, error: null);
  final parsed = QuantityTextField.parseQuantity(text, allowsDecimal: true);
  if (parsed == null) {
    return (
    value: null,
    error: ReceiptValidator.isIncompleteNumber(text)
        ? null
        : AppErrors.quantityTooLarge,
    );
  }
  final error = ReceiptValidator.validateQuantity(
    parsed,
    allowsDecimal: allowsDecimal,
  );
  return (value: error == null ? parsed : null, error: error);
}

/// Κοινός πυρήνας ανάγνωσης πεδίου cents (Τιμή/Έκπτωση): `value` = η τιμή
/// ΜΟΝΟ όταν πέρασε το parse, `error` = `priceTooLarge` σε μη-κενό,
/// ολοκληρωμένο αλλά εκτός ορίου (ενημέρωση αντί για καθρέφτη μεθόδου).
({int? value, String? error}) _parseCentsField(
  TextEditingController controller,
) {
  final text = controller.text;
  if (text.trim().isEmpty) return (value: null, error: null);
  final cents = CurrencyTextField.parseCents(text);
  if (cents == null) {
    return (
    value: null,
    error: ReceiptValidator.isIncompleteNumber(text)
        ? null
        : AppErrors.priceTooLarge,
    );
  }
  return (value: cents, error: null);
}

/// Τιμή του πεδίου σε cents (Βήμα 6δ) — ίδιο contract με το
/// `_quantityCheck` (`ReceiptValidator.validatePriceCents`, §2.2:217).
({int? value, String? error}) _priceCheck(
  TextEditingController controller,
) {
  final parsed = _parseCentsField(controller);
  if (parsed.value == null) return parsed;
  final error = ReceiptValidator.validatePriceCents(parsed.value!);
  return (value: error == null ? parsed.value : null, error: error);
}

/// Έκπτωση του πεδίου σε cents (§2.2): κενό → 0 (καμία)· αλλιώς parse +
/// `validateDiscountCents` έναντι της (τελικής) [priceCents]. `null` τιμή
/// (άκυρη/μη-ολοκληρωμένη τιμή) → κανένας έλεγχος σχέσης ακόμη (το Add
/// μένει ανενεργό από την τιμή).
({int? value, String? error}) _discountCheck(
  TextEditingController controller,
  int? priceCents,
) {
  final parsed = _parseCentsField(controller);
  if (controller.text.trim().isEmpty) {
    return (value: 0, error: null);
  }
  if (parsed.value == null) return parsed;
  if (priceCents == null) return (value: parsed.value, error: null);
  final error =
      ReceiptValidator.validateDiscountCents(parsed.value!, priceCents);
  return (value: error == null ? parsed.value : null, error: error);
}
