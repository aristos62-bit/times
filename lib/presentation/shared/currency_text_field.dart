/// SPoT shared widget: πεδίο τιμής σε ευρώ — Φάση 3 Βήμα 5 (DESIGN §2.4).
///
/// Υποστηρίζει δεκαδικά με βάση το `priceDecimalDigits` (χωρίς hardcoded),
/// δέχεται ως διαχωριστή και `.` και `,`, και μετατρέπει σε «λεπτά» (cents)
/// ακέραια με το [parseCents] — ΚΑΝΕΝΑ double ενδιάμεσο (decision Beat 5:
/// «χωρίς κίνδυνο στρογγυλοποίησης»). Το parsing/formatting είναι SPoT εδώ:
/// κάθε άλλο σημείο (π.χ. draft list) χρησιμοποιεί τα ίδια helpers.
///
/// Το σύμβολο νομίσματος (συνήθως `AppStrings.currencySymbol`, σε Βήμα 5γ)
/// περνά ως [suffixText] από τον καλών — η εικόνα/label είναι του καλούντος
/// (SPoT app_strings, §1.1). Η συμπεριφορά του πεδίου είναι «dumb»: format,
/// δεν αποθηκεύει, δεν ανοίγει βάση (§2.0.1 — καμία repo πρόσβαση).
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'decimal_input_formatter.dart';

/// Πεδίο εισόδου τιμής σε ευρώ. Ο καλών κρατά το controller και διαβάζει
/// την τιμή μέσω [parseCents] όταν τη χρειαστεί (π.χ. στο submit).
class CurrencyTextField extends StatelessWidget {
  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.suffixText,
    this.prefixIcon,
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

  /// Προαιρετικό suffix (π.χ. σύμβολο € — SPoT app_strings στο Βήμα 5γ).
  final String? suffixText;

  /// Προαιρετικό εικονίδιο αριστερά (π.χ. Icons.euro).
  final Widget? prefixIcon;

  /// Κλήση σε κάθε αλλαγή κειμένου (για live validation του Add button).
  final ValueChanged<String>? onChanged;

  /// Auto-focus όταν μπει στο δέντρο.
  final bool autofocus;

  /// Action του πληκτρολογίου (default: επόμενο πεδίο).
  final TextInputAction textInputAction;

  /// Μετατρέπει το κείμενο σε ακέραιο αριθμό «λεπτών» (cents), ΑΛΦΑΡΙΘΜΗΤΙΚΑ —
  /// χωρίς ενδιάμεσο double (Beat 5). Δέχεται `.` ή `,` ως διαχωριστή, μέχρι
  /// [AppConstants.priceDecimalDigits] δεκαδικά. Επιστρέφει `null` για κενό,
  /// μη-έγκυρο ή πάνω από [AppConstants.maxPriceCents] (όριο εισόδου).
  static int? parseCents(String? text) {
    if (text == null) return null;
    final trimmed = text.trim();
    final match =
        RegExp(r'^(\d+)(?:[.,](\d{1,2}))?$').firstMatch(trimmed);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fraction = match.group(2) ?? '';
    final cents = whole * 100 + int.parse(fraction.padRight(2, '0'));
    if (cents > AppConstants.maxPriceCents) return null;
    return cents;
  }

  /// Μορφοποιεί λεπτά (cents) σε κείμενο «ευρώ,δεκαδικά» με κόμμα — χωρίς
  /// intl/locale (hermetic tests, Beat 5 απόφαση). Π.χ. `250 → "2,50"`.
  static String formatCents(int cents) {
    final whole = cents ~/ 100;
    final fraction = (cents % 100).toString().padLeft(2, '0');
    return '$whole,$fraction';
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        DecimalInputFormatter(
          maxDecimalDigits: AppConstants.priceDecimalDigits,
          maxLength: AppConstants.priceMaxLength,
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