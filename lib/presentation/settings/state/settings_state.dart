/// SPoT state — Διαχείριση κατηγοριών/υποκατηγοριών (§2.3 DESIGN /
/// Φάση 4 Βήμα 4).
///
/// Κατάσταση του `CategoryManagementController` (plain Notifier): ΜΟΝΟ το
/// busy-flag `isWorking` (double-tap guard, pattern `isSaving` του
/// `ReceiptFormState`). Το δέντρο ΔΕΝ ζει εδώ — έρχεται από τον
/// `categoryTreeStreamProvider` (stream, §2.5)· η πύλη διαγραφής από τους
/// `canDelete*/inUseCount*` providers. Κοινό αρχείο Βημάτων 4–5 (§2.3:261).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_state.freezed.dart';

/// Κατάσταση διαχείρισης καταλόγου — μόνο busy-flag.
@freezed
abstract class SettingsState with _$SettingsState {
  /// `isWorking` — CRUD σε εξέλιξη: το UI απενεργοποιεί add/edit/delete
  /// (pattern `isSaving` §2.2 — το state παραμένει σύγχρονο, plain Notifier).
  const factory SettingsState({@Default(false) bool isWorking}) =
      _SettingsState;
}
