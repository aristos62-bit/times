/// Dumb πεδίο έκπτωσης γραμμής (§2.2) — λεπτός wrapper πάνω στο
/// `CurrencyTextField` (SPoT parse/format `parseCents`, §2.4).
///
/// Η έκπτωση εισάγεται ΘΕΤΙΚΗ (λεπτά προς αφαίρεση από την τιμή μονάδας)·
/// το «−» είναι σημασιολογία (αφαίρεση), όχι πρόσημο εισόδου (το regex του
/// `parseCents` αποκλείει το «−»). Κενό ≡ 0 (καμία έκπτωση).
/// Dumb (§2.0): format + προβολή σφάλματος μόνο — ο κανόνας `0≤d≤p` ζει
/// στον `ReceiptValidator`, η απόφαση Add στο section.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../shared/currency_text_field.dart';

/// Πεδίο «Έκπτωση» (ανά μονάδα, €). Ο γονέας κρατά τον controller και
/// διαβάζει την τιμή μέσω `CurrencyTextField.parseCents`.
class DiscountField extends StatelessWidget {
  const DiscountField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  /// Controller του πεδίου — τον κατέχει ο γονέας (σύμβαση φόρμας).
  final TextEditingController controller;

  /// Προαιρετικό inline μήνυμα σφάλματος (SPoT `AppErrors` από τον
  /// καλούντα) — `null` = κανένα σφάλμα.
  final String? errorText;

  /// Κλήση σε κάθε αλλαγή κειμένου (για live validation του Add button).
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CurrencyTextField(
      controller: controller,
      labelText: AppStrings.fieldDiscount,
      suffixText: AppStrings.currencySymbol,
      prefixIcon: const Icon(Icons.percent_outlined),
      errorText: errorText,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
    );
  }
}
