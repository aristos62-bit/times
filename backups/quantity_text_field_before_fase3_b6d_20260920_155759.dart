/// SPoT shared widget: πεδίο ποσότητας — Φάση 3 Βήμα 5 (DESIGN §2.4).
///
/// Υποστηρίζει δεκαδικά με βάση το `quantityDecimalDigits` και δέχεται flag
/// [allowsDecimal] (DESIGN §2.4: `QuantityTextField`), ώστε μονάδες χωρίς
/// κλάσματα (π.χ. «τεμάχια») να δέχονται ΜΟΝΟ ψηφία — η γραμμή προσθήκης
/// χρησιμοποιεί αυτό το flag ανάλογα με το `Unit.allowsDecimal`.
///
/// Διαχωριστής και `.` και `,`· SPoT parsing/formatting εδώ ([parseQuantity],
/// [formatQuantity]). Το suffix (π.χ. συντομογραφία μονάδας «κιλ») περνά από
/// τον καλών. Widget «dumb»: δεν αποθηκεύει, δεν ανοίγει βάση (§2.0.1).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'decimal_input_formatter.dart';

/// Πεδίο εισόδου ποσότητας. Ο καλών κρατά το controller και διαβάζει την
/// τιμή μέσω [parseQuantity] όταν τη χρειαστεί (π.χ. στο submit).
class QuantityTextField extends StatelessWidget {
  const QuantityTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.suffixText,
    this.prefixIcon,
    this.allowsDecimal = true,
    this.onChanged,
    this.autofocus = false,
    this.textInputAction = TextInputAction.next,
  });

  /// Controller του πεδίου — τον κατέχει ο γονέας (σύμβαση φόρμας).
  final TextEditingController controller;

  /// Label του πεδίου (SPoT app_strings, §1.1).
  final String labelText;

  /// Προαιρετικό hint του πεδίου.
  final String? hintText;

  /// Προαιρετικό suffix (π.χ. συντομογραφία μονάδας — Βήμα 5γ).
  final String? suffixText;

  /// Προαιρετικό εικονίδιο αριστερά.
  final Widget? prefixIcon;

  /// `true` = δέχεται δεκαδικά (`quantityDecimalDigits`) · `false` = μόνο
  /// ψηφία (μονάδες χωρίς κλάσματα, DESIGN §2.4 / §2.2:218).
  final bool allowsDecimal;

  /// Κλήση σε κάθε αλλαγή κειμένου (για live validation του Add button).
  final ValueChanged<String>? onChanged;

  /// Auto-focus όταν μπει στο δέντρο.
  final bool autofocus;

  /// Action του πληκτρολογίου (default: επόμενο πεδίο).
  final TextInputAction textInputAction;

  /// Μετατρέπει κείμενο σε αριθμό (double — το quantity αποθηκεύεται REAL,
  /// DESIGN §3). Δέχεται `.` ή `,`, μέχρι `quantityDecimalDigits` δεκαδικά
  /// (ή μόνο ψηφία όταν [allowsDecimal]=false). Επιστρέφει `null` για κενό,
  /// μη-έγκυρο ή πάνω από [AppConstants.maxQuantity].
  static double? parseQuantity(String? text, {required bool allowsDecimal}) {
    if (text == null) return null;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final pattern = allowsDecimal
        ? RegExp(r'^(\d+)(?:[.,](\d{1,3}))?$')
        : RegExp(r'^(\d+)$');
    final match = pattern.firstMatch(trimmed);
    if (match == null) return null;

    // Το integer-only pattern έχει μόνο group 1 — το group 2 ΔΕΝ υπάρχει.
    final fraction = match.groupCount >= 2 ? (match.group(2) ?? '') : '';
    // «1,5» κιλά → 1.500 (3 δεκαδικά) → double 1.5 (χωρίς float artifacts).
    final double value =
        double.parse('${match.group(1)!}.${fraction.padRight(3, '0')}');
    if (value > AppConstants.maxQuantity) return null;
    return value;
  }

  /// Μορφοποιεί ποσότητα σε κείμενο με κόμμα, χωρίς trailing μηδενικά —
  /// χωρίς intl (hermetic). Π.χ. `2.5 → "2,5"`, `2.0 → "2"`, `2.505 → "2,505"`.
  static String formatQuantity(double quantity) {
    var fixed = quantity.toStringAsFixed(AppConstants.quantityDecimalDigits);
    fixed = fixed.replaceAll(RegExp(r'0+$'), '');
    fixed = fixed.replaceAll(RegExp(r'\.$'), '');
    return fixed.replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: textInputAction,
      keyboardType:
          TextInputType.numberWithOptions(decimal: allowsDecimal),
      inputFormatters: [
        DecimalInputFormatter(
          allowDecimal: allowsDecimal,
          maxDecimalDigits: AppConstants.quantityDecimalDigits,
          maxLength: AppConstants.quantityMaxLength,
        ),
      ],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}