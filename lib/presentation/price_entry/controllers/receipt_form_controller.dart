/// Παρέχει την κατάσταση της φόρμας απόδειξης (§2.2 DESIGN / Φάση 3 Βήμα 3).
///
/// `Notifier`, όχι AsyncNotifier — το state είναι σύγχρονο (δεν έρχεται από
/// τη βάση)· το AsyncValue.when ισχύει για data sections, όχι για το header.
/// Ο `build()` ΧΩΡΙΣ εξάρτηση από repository → η βάση ΔΕΝ ανοίγει όσο η
/// σελίδα δείχνει μόνο το header. Η μόνη repo πρόσβαση είναι με user action:
/// η inline δημιουργία προμηθευτή («+») μέσω `createSupplier`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/greek_text_normalizer.dart';
import '../../../data/local/app_database.dart';
import '../../../data/providers/database_providers.dart';
import '../state/receipt_form_state.dart';

/// SPoT provider της φόρμας. Όχι autoDispose (§2.2:221): το IndexedStack
/// κρατά τη ζωντανή σελίδα σε αλλαγή tab — η επιλεγμένη ημερομηνία επιβιώνει.
final receiptFormControllerProvider = NotifierProvider<ReceiptFormController,
    ReceiptFormState>(ReceiptFormController.new);

/// Controller της απόδειξης — header (ημερομηνία + προμηθευτής, Βήμα 3) +
/// draft γραμμές «καλαθιού» (Βήμα 5γ) + αποθήκευση (Βήμα 5δ).
class ReceiptFormController extends Notifier<ReceiptFormState> {
  /// Αρχική κατάσταση: σημερινή ημερομηνία (dateOnly), χωρίς προμηθευτή.
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

  /// Ορίζει τον επιλεγμένο προμηθευτή (§2.4 SearchableDropdownField).
  /// Equality gate κατά `id`: ίδιος προμηθευτής → χωρίς re-notify (ίδιο
  /// μοτίβο με `setDate`). `null` = αποεπιλογή.
  void setSupplier(Supplier? supplier) {
    if (state.supplier?.id == supplier?.id) return;
    state = state.copyWith(supplier: supplier);
    AppLogger.info(LogTag.ui, 'Επιλογή προμηθευτή: ${supplier?.name ?? '(κανένας)'}');
  }

  /// Προσθέτει γραμμή στο «καλάθι» (§2.2 · Βήμα 5γ). Καμία εγγραφή στη βάση —
  /// το insert γίνεται ατομικά στο save (Βήμα 5δ). Το ίδιο είδος σε πολλές
  /// γραμμές ΕΠΙΤΡΕΠΕΤΑΙ — δεν γίνεται merge (§2.2:237). Η επικύρωση τιμών
  /// (unit/quantity/price) ανήκει στο section widget (κουμπί ανενεργό όταν
  /// άκυρα)· εδώ φυλάσσεται μόνο έγκυρη γραμμή.
  void addDraftLine(DraftReceiptLine line) {
    state = state.copyWith(draftLines: [...state.draftLines, line]);
    AppLogger.info(
      LogTag.ui,
      'Προσθήκη γραμμής: ${line.itemName} × ${line.quantity} '
      '${line.unitAbbreviation} (${state.draftLines.length} γραμμές)',
    );
  }

  /// Αφαιρεί γραμμή από το «καλάθι» κατά [index]. Εκτός ορίων index →
  /// αγνοείται (defensive — το UI δείχνει μόνο έγκυρες γραμμές).
  void removeDraftLine(int index) {
    if (index < 0 || index >= state.draftLines.length) return;
    final removed = state.draftLines[index];
    state = state.copyWith(
      draftLines: [
        ...state.draftLines.sublist(0, index),
        ...state.draftLines.sublist(index + 1),
      ],
    );
    AppLogger.info(LogTag.ui, 'Αφαίρεση γραμμής: ${removed.itemName}');
  }

  /// Αποθηκεύει ολόκληρη την απόδειξη (§2.2 · Βήμα 5δ): insert `Receipt` +
  /// όλες οι `ReceiptLine` σε ΜΙΑ transaction μέσω `insertReceiptWithLines`
  /// (atomicity — είτε όλα είτε τίποτα, §2.2:211).
  ///   * Επιτυχία → καθαρισμός φόρμας (`resetForm`, §2.2:212)· το
  ///     `recent_receipts_list` ανανεώνεται αυτόματα μέσω stream (§2.2:212).
  ///   * Αποτυχία (`SaveReceiptException` από το repository Ή απρόβλεπτο
  ///     σφάλμα, π.χ. μη-mapped εξαίρεση) → το flag σβήνει ΠΑΝΤΑ (αλλιώς το
  ///     κουμπί μένει ανενεργό για πάντα — ο provider δεν είναι autoDispose),
  ///     τα draft δεδομένα ΠΑΡΑΜΕΝΟΥΝ (§2.2:213) και η εξαίρεση ανεβαίνει
  ///     ΑΝΕΓΓΙΧΤΗ στο widget — υπεύθυνο για το feedback (`e.userMessage`
  ///     μέσω AppFeedback, pattern `createSupplier`· απρόβλεπτο → γενικό
  ///     `AppErrors.saveFailed`). Τα απρόβλεπτα καταγράφονται εδώ (tag DB).
  ///
  /// Defensive guards (χωρίς DB touch): προμηθευτής null Ή κενό «καλάθι» →
  /// `SaveReceiptException` (το UI τα αποκλείει με disabled-OR, §2.2 — εδώ
  /// safety-net για programmatic κλήσεις). Επανεισδοχή ενώ `isSaving` →
  /// no-op (double-tap guard, §2.2:235 — το κουμπί είναι ανενεργό όσο σώζει).
  /// `ref.mounted` μετά το await (pattern `_search` Βήματος 4): disposed →
  /// παράλειψη ενημέρωσης state.
  Future<void> saveReceipt() async {
    if (state.isSaving) return;
    final supplier = state.supplier;
    final lines = state.draftLines;
    final date = state.date;
    if (supplier == null || lines.isEmpty) {
      throw const SaveReceiptException();
    }

    state = state.copyWith(isSaving: true);
    try {
      final id = await ref.read(receiptRepositoryProvider).insertReceiptWithLines(
        date: date,
        supplierId: supplier.id,
        lines: [
          for (final line in lines)
            (
            itemId: line.itemId,
            unitId: line.unitId,
            quantity: line.quantity,
            priceCents: line.priceCents,
            ),
        ],
      );
      if (!ref.mounted) return; // disposed ενώ έτρεχε το save → παράλειψη
      resetForm();
      AppLogger.info(
        LogTag.db,
        'Αποθήκευση απόδειξης #$id (${lines.length} γραμμές)',
      );
    } catch (e, s) {
      if (ref.mounted) state = state.copyWith(isSaving: false);
      if (e is! SaveReceiptException) {
        AppLogger.error(
          LogTag.db,
          'Απρόβλεπτο σφάλμα αποθήκευσης απόδειξης',
          e,
          s,
        );
      }
      rethrow; // drafts ΜΕΝΟΥΝ (§2.2:213) — το widget δείχνει το feedback
    }
  }

  /// Καθαρισμός φόρμας μετά από επιτυχημένο save (§2.2:212): σημερινή
  /// ημερομηνία, κανένας προμηθευτής, κενό «καλάθι».
  void resetForm() {
    state = ReceiptFormState(date: DateUtils.dateOnly(DateTime.now()));
    AppLogger.info(LogTag.ui, 'Καθαρισμός φόρμας απόδειξης');
  }

  /// Δημιουργεί προμηθευτή από την inline επιλογή «+» (§2.4). Επιστρέφει
  /// record `{ supplier, created }`:
  ///   * `supplier` = ο επιλεγμένος στο state `Supplier` (νέος ή ήδη-υπάρχων)
  ///     ή `null` αν το [name] είναι κενό/whitespace (κενό → χωρίς αποτέλεσμα)
  ///     ή αν το insert/NULL επέστρεψε μη-αναμενόμενο null read-back.
  ///   * `created` = true όταν ΜΠΗΚΕ νέα γραμμή στη βάση (καθαρό γεγονός DB)·
  ///     false σε κενό/υπάρχον. Επιτρέπει στο widget να διακρίνει τα δύο
  ///     μηνύματα ροής (AppMessages.supplierAdded vs supplierExists).
  ///
  /// Soft duplicate-check (§2.2/§3): `getByNormalizedName` exact-match πριν το
  /// insert → αν υπάρχει, ΔΕΝ εισάγει· επιλέγει τον υπάρχοντα (το UNIQUE της
  /// βάσης μένει defense-in-depth μόνο). Σφάλμα DB προκύπτει ως
  /// `DataLoadException` από το repository και ανεβαίνει ανέγγιχτο στο widget,
  /// που είναι υπεύθυνο για το feedback (AppFeedback).
  Future<({Supplier? supplier, bool created})> createSupplier(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return (supplier: null, created: false);

    final repo = ref.read(supplierRepositoryProvider);
    final existing = await repo.getByNormalizedName(
      GreekTextNormalizer.normalize(trimmed),
    );
    if (existing != null) {
      setSupplier(existing);
      return (supplier: existing, created: false);
    }

    final id = await repo.insert(name: trimmed);
    final created = await repo.getById(id);
    if (created != null) setSupplier(created);
    return (supplier: created, created: true);
  }
}