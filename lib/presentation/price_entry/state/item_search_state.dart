/// SPoT state — Αναζήτηση είδους (§2.4 DESIGN / Φάση 3 Βήμα 4).
///
/// Κατάσταση του `ItemSearchController` (AsyncNotifier). Ο σταθμός διέπει
/// με ποιον τρόπο κάνει render το inline panel (`item_search_field.dart`):
///   * idle      — πριν πληκτρολογήσει ο χρήστης (ή κάτω από minChars).
///   * searching — ο Debouncer έτρεξε· αναζήτηση σε εξέλιξη (spinner).
///   * found     — ≥1 αποτέλεσμα (λίστα στον `results`).
///   * notFound  — κανένα αποτέλεσμα (μήνυμα «Δεν βρέθηκε» + «+»).
///   * error     — σφάλμα DataLoadException (μήνυμα + retry).
///
/// `selectedItem != null` δηλώνει ITEM_SELECTED (§2.4): το field δείχνει το
/// banner «Αλλαγή»· η μεταβίβαση στο state της φόρμας γίνεται από τη σελίδα
/// (Βήμα 5) μέσω `setItem` στον ReceiptFormState — όχι εδώ.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/local/app_database.dart';

part 'item_search_state.freezed.dart';

/// Στάδια της αναζήτησης είδους στο inline panel.
enum ItemSearchStatus { idle, searching, found, notFound, error }

/// Κατάσταση της αναζήτησης ειδών + inline δημιουργίας.
@freezed
abstract class ItemSearchState with _$ItemSearchState {
  /// [query] — debounced query που έτρεξε (ή κενό στα idle).
  /// [status] — στάδιο της αναζήτησης (§2.4).
  /// [results] — αποτελέσματα της τελευταίας αναζήτησης (found).
  /// [selectedItem] — «null» = κανένα επιλεγμένο είδος.
  /// [errorOccurred] — flag για το retry μετά από σφάλμα (error).
  const factory ItemSearchState({
    @Default('') String query,
    @Default(ItemSearchStatus.idle) ItemSearchStatus status,
    @Default(<Item>[]) List<Item> results,
    Item? selectedItem,
    @Default(false) bool errorOccurred,
  }) = _ItemSearchState;
}