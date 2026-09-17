/// Παρέχει την κατάσταση της φόρμας απόδειξης (§2.2 DESIGN / Φάση 3 Βήμα 2).
///
/// `Notifier`, όχι AsyncNotifier — το state είναι σύγχρονο (δεν έρχεται από
/// τη βάση)· το AsyncValue.when ισχύει για data sections, όχι για το header.
/// ΧΩΡΙΣ εξάρτηση από repository → η βάση ΔΕΝ ανοίγει όσο η σελίδα δείχνει
/// μόνο το header.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_logger.dart';
import '../state/receipt_form_state.dart';

/// SPoT provider της φόρμας. Όχι autoDispose (§2.2:221): το IndexedStack
/// κρατά τη ζωντανή σελίδα σε αλλαγή tab — η επιλεγμένη ημερομηνία επιβιώνει.
final receiptFormControllerProvider = NotifierProvider<ReceiptFormController,
    ReceiptFormState>(ReceiptFormController.new);

/// Controller της απόδειξης — header (ημερομηνία, Βήμα 2).
class ReceiptFormController extends Notifier<ReceiptFormState> {
  /// Αρχική κατάσταση: σημερινή ημερομηνία (dateOnly).
  @override
  ReceiptFormState build() {
    return ReceiptFormState(date: DateUtils.dateOnly(DateTime.now()));
  }

  /// Ορίζει την ημερομηνία απόδειξης (από showDatePicker). Κανονικοποιεί σε
  /// ημέρα (dateOnly) ώστε η ώρα να μην «προσγειωθεί» σε εμφάνιση/storage.
  void setDate(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    if (normalized == state.date) return; // ίδια μέρα → χωρίς re-notify
    state = state.copyWith(date: normalized);
    AppLogger.info(LogTag.ui, 'Ημερομηνία απόδειξης: ${normalized.toIso8601String()}');
  }
}