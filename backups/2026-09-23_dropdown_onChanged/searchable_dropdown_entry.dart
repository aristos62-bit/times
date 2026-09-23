// Εσωτερικές «γραμμές» του overlay του `SearchableDropdownField` (§2.4).
// Part αρχείο (Φάση 3 Βήμα 6ε): ξεχωρίστηκε ώστε το κύριο αρχείο να μένει
// κάτω από το όριο των 500 γραμμών (AGENTS κανόνας 7). Τα private types
// παραμένουν ορατά μόνο μέσα στο library του `searchable_dropdown_field.dart`.
part of 'searchable_dropdown_field.dart';

/// Οι «γραμμές» του overlay. Sealed: αποτέλεσμα ή «+» (create). Κρατά τη
/// λίστα του `RawAutocomplete` πάντα μη-κενή όταν υπάρχει query, ώστε το
/// «+» να είναι ορατό ΑΚΟΜΑ με 0 αποτελέσματα (§2.4).
sealed class _Entry<T> {
  const _Entry();
}

final class _ResultEntry<T> extends _Entry<T> {
  const _ResultEntry(this.value);
  final T value;
}

final class _CreateEntry<T> extends _Entry<T> {
  const _CreateEntry(this.query);
  final String query;
}