/// SPoT καθαρού συνόλου γραμμής (§3 DESIGN).
///
/// Η ΜΟΝΗ υλοποίηση του `((priceCents − discountCents) × quantity).round()`
/// — stored writes (ReceiptLineDao insert/update) ΚΑΙ display mirrors
/// (draft list, statistics export) περνάνε από εδώ (κανένα inline
/// duplicate). Pure (χωρίς state/IO/logging — κανένα DebugConfig tag) —
/// testable χωρίς βάση.
library;

/// Καθαρό σύνολο γραμμής σε λεπτά — στρογγυλοποίηση στο πλησιέστερο cent.
int lineTotalCents({
  required int priceCents,
  required int discountCents,
  required double quantity,
}) => ((priceCents - discountCents) * quantity).round();
