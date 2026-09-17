/// SPoT state — Φόρμα εισαγωγής απόδειξης (§2.2 DESIGN / Φάση 3 Βήμα 2).
///
/// Freezed immutable state — επεκτείνεται στα Βήματα 3-5 (supplier,
/// draftLines[], isSaving) με το ίδιο pattern. Προς το παρόν μόνο `date`:
/// ο αριθμός απόδειξης ΔΕΝ ανήκει εδώ — είναι το internal AUTOINCREMENT id
/// της Receipt (§3: εμφάνιση στη λίστα Βήμα 7).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_form_state.freezed.dart';

/// Κατάσταση της φόρμας απόδειξης — μόνο ημερομηνία (Βήμα 2).
@freezed
abstract class ReceiptFormState with _$ReceiptFormState {
  /// `date` — ημερομηνία της απόδειξης (κανονικοποιημένη σε μέρα, χωρίς ώρα,
  /// μέσω `DateUtils.dateOnly` στο controller — §2.2).
  const factory ReceiptFormState({required DateTime date}) = _ReceiptFormState;
}