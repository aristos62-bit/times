/// SPoT συνόλων γραμμής (§3 DESIGN).
///
/// Η ΜΟΝΗ υλοποίηση των τύπων γραμμής — stored writes (ReceiptLineDao
/// insert/update) ΚΑΙ display mirrors (draft list, statistics export)
/// περνάνε από εδώ (κανένα inline duplicate). Pure (χωρίς state/IO/
/// logging — κανένα DebugConfig tag) — testable χωρίς βάση.
library;

/// Καθαρό σύνολο γραμμής σε λεπτά — στρογγυλοποίηση στο πλησιέστερο cent.
int lineTotalCents({
  required int priceCents,
  required int discountCents,
  required double quantity,
}) =>
    ((priceCents - discountCents) * quantity).round();

/// Μικτό σύνολο γραμμής (χωρίς έκπτωση) — στήλη «Σύνολο» (01-10).
/// Μαζί με [discountTotalCents] μπορεί να διαφέρει ±1 λεπτό από το
/// [lineTotalCents] σε freak-rounding (ίδια οικογένεια με το τεκμηριωμένο
/// ±1 total-mode)· αλήθεια = stored.
int grossTotalCents({
  required int priceCents,
  required double quantity,
}) =>
    (priceCents * quantity).round();

/// Συνολική έκπτωση γραμμής — στήλη «Έκπτωση» (01-10, σύνολο όχι μοναδιαία).
int discountTotalCents({
  required int discountCents,
  required double quantity,
}) =>
    (discountCents * quantity).round();
