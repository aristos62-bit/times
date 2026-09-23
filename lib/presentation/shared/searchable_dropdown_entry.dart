// Εσωτερικές «γραμμές» του overlay του `SearchableDropdownField` (§2.4).
// Part αρχείο (Φάση 3 Βήμα 6ε / Βήμα 21): ξεχωρίστηκε ώστε το κύριο αρχείο να
// μένει κάτω από το όριο των 500 γραμμών (AGENTS κανόνας 7). Τα private types
// και το render `_buildEntryTile` παραμένουν ορατά μόνο μέσα στο library του
// `searchable_dropdown_field.dart` (τα imports του κύριου ισχύουν εδώ).
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

/// Μία γραμμή του overlay (result ή «+»). Accessibility §1.6: ListTile
/// συνθέτει το semantic label του από title (label του αποτελέσματος /
/// «Νέος προμηθευτής "x"») + onTap — δεν χρειάζεται επιπλέον Semantics.
/// Top-level (part αρχείο, όχι μέθοδος της State) ώστε το κύριο αρχείο να
/// μένει <500 γρ. — τα δεδομένα του widget περνούν ως ορίσματα.
Widget _buildEntryTile<T>(
  BuildContext context,
  _Entry<T> entry,
  ValueChanged<_Entry<T>> onSelected, {
  required Icon resultLeadingIcon,
  required String Function(T value) labelOf,
  String Function(String query)? createLabel,
  required bool isCreating,
}) {
  return switch (entry) {
    _ResultEntry<T>(value: final value) => ListTile(
        dense: true,
        leading: resultLeadingIcon,
        title: Text(labelOf(value)),
        onTap: () => onSelected(entry),
      ),
    _CreateEntry<T>(query: final query) => ListTile(
        dense: true,
        leading: const Icon(Icons.add_circle_outline),
        title: Text(createLabel!(query)),
        trailing: isCreating
            ? SizedBox(
                width: AppConstants.smallSpinnerSize,
                height: AppConstants.smallSpinnerSize,
                child: const CircularProgressIndicator(
                  strokeWidth: AppConstants.spinnerStrokeWidth,
                ),
              )
            : null,
        onTap: () => onSelected(entry),
        enabled: !isCreating,
      ),
  };
}