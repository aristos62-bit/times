/// SPoT shared `TextInputFormatter` για δεκαδικές εισόδους — Φάση 3 Βήμα 5
/// (DESIGN §2.4: `CurrencyTextField` / `QuantityTextField`).
///
/// ΕΝΔΙΑΦΕΡΟΝ: καθαριστής («sanitizer») του νέου κειμένου χωρίς εξάρτηση
/// από το `oldValue` — κάθε είσοδος περνάει από τους ίδιους κανόνες:
///   1. Κρατάει μόνο ψηφία (και, αν `allowDecimal`, τους διαχωριστές `.`/`,`).
///   2. Κρατάει μόνο τον ΠΡΩΤΟ διαχωριστή — όλοι οι μεταγενέστεροι σβήνονται
///      (π.χ. `1,2,3` → `1,23` με όριο 2 δεκαδικών). Όταν το ακέραιο μέρος
///      λείπει (π.χ. `,5`) τοποθετεί `0` μπροστά (`0,5`) — αποδεκτό κείμενο
///      για το parsing.
///   3. Περιορίζει τα δεκαδικά ψηφία σε `maxDecimalDigits`.
///   4. Περιορίζει το συνολικό μήκος σε `maxLength` (soft input guard — το
///      ουσιαστικό όριο τιμής θέτουν οι `parseCents`/`parseQuantity`).
///
/// Τα όρια περνούν ως παράμετροι από τους καλούντες (ποτέ hardcoded) — SPoT
/// AppConstants: `priceDecimalDigits`, `quantityDecimalDigits`,
/// `priceMaxLength`, `quantityMaxLength`.
library;

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';

/// Καθαριστής εισόδου για δεκαδικούς αριθμούς (`.`/`,` ως διαχωριστής).
class DecimalInputFormatter extends TextInputFormatter {
  const DecimalInputFormatter({
    this.allowDecimal = true,
    this.maxDecimalDigits = AppConstants.priceDecimalDigits,
    this.maxLength,
  });

  /// `true` = δέχεται δεκαδικό διαχωριστή (π.χ. ποσότητα σε κιλά) ·
  /// `false` = μόνο ψηφία (π.χ. ποσότητα σε μονάδες χωρίς κλάσματα).
  final bool allowDecimal;

  /// Πόσα δεκαδικά ψηφία επιτρέπονται ΜΕΤΑ τον διαχωριστή.
  final int maxDecimalDigits;

  /// Μέγιστο συνολικό μήκος κειμένου (χαρακτήρες) — `null` = χωρίς όριο.
  final int? maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    // 1) Μόνο επιτρεπτοί χαρακτήρες (ψηφία + προαιρετικά διαχωριστές).
    final allowed = allowDecimal ? RegExp(r'[^0-9.,]') : RegExp(r'[^0-9]');
    text = text.replaceAll(allowed, '');

    if (allowDecimal) {
      // 2) Μοναδικός διαχωριστής — κρατάμε τον ΠΡΩΤΟ `.` ή `,`.
      final separatorIndex = _firstSeparatorIndex(text);
      if (separatorIndex != -1) {
        final separator = text[separatorIndex];
        final integerPart = text.substring(0, separatorIndex);
        var decimalPart = text
            .substring(separatorIndex + 1)
            .replaceAll(RegExp(r'[.,]'), '');
        // 3) Περιορισμός δεκαδικών ψηφίων.
        if (decimalPart.length > maxDecimalDigits) {
          decimalPart = decimalPart.substring(0, maxDecimalDigits);
        }
        text = '$integerPart$separator$decimalPart';
        // Έλλειψη ακέραιου μέρους (`0,5` αντί για `,5`) — έγκυρο για parsing.
        if (text == separator) {
          text = '';
        } else if (text.startsWith(separator)) {
          text = '0$text';
        }
      }
    }

    // 4) Soft input guard μήκους — το ουσιαστικό όριο θέτουν οι parse*.
    if (maxLength != null && text.length > maxLength!) {
      text = text.substring(0, maxLength!);
    }

    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Θέση του πρώτου διαχωριστή (`/`) στη συμβολοσειρά, ή -1 αν δεν υπάρχει.
  int _firstSeparatorIndex(String text) {
    final dot = text.indexOf('.');
    final comma = text.indexOf(',');
    if (dot == -1) return comma;
    if (comma == -1) return dot;
    return dot < comma ? dot : comma;
  }
}