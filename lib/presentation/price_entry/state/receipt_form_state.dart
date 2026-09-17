/// SPoT state — Φόρμα εισαγωγής απόδειξης (§2.2 DESIGN / Φάση 3 Βήμα 3).
///
/// Freezed immutable state — επεκτείνεται στα Βήματα 3-5 (draftLines[],
/// isSaving) με το ίδιο pattern. Ο αριθμός απόδειξης ΔΕΝ ανήκει εδώ — είναι
/// το internal AUTOINCREMENT id της Receipt (§3: εμφάνιση στη λίστα Βήμα 7).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/local/app_database.dart';

part 'receipt_form_state.freezed.dart';

/// Κατάσταση της φόρμας απόδειξης — ημερομηνία + επιλεγμένος προμηθευτής.
@freezed
abstract class ReceiptFormState with _$ReceiptFormState {
  /// `date` — ημερομηνία της απόδειξης (κανονικοποιημένη σε μέρα, χωρίς ώρα,
  /// μέσω `DateUtils.dateOnly` στο controller — §2.2).
  const factory ReceiptFormState({
    required DateTime date,
    /// `supplier` — ο επιλεγμένος προμηθευτής (Βήμα 3), «null» = κανένας.
    /// Drift data-class (app_database.dart): immutable με value equality —
    /// συμβατό με το Freezed equality/copyWith χωρίς επιπλέον annotations.
    Supplier? supplier,
  }) = _ReceiptFormState;
}