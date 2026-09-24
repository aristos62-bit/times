/// Controller διαχείρισης προμηθευτών (§2.3 DESIGN / CRUD 24-09-2026).
///
/// Plain `Notifier<SettingsState>` (όχι AsyncNotifier): το state είναι
/// σύγχρονο (μόνο `isWorking` flag)· η λίστα έρχεται από τον
/// `suppliersStreamProvider` και η πύλη από τους `canDeleteSupplierProvider` /
/// `receiptCountSupplierProvider`. Pattern `CategoryManagementController`
/// (σύγχρονο state + async actions με flag). NON-autoDispose (§2.2:221,
/// IndexedStack).
///
/// Dup-check exact (`getByNormalizedName` — ο πίνακας Supplier ΕΧΕΙ UNIQUE
/// `normalizedName`, §3 — καλύτερο από in-memory). Το rename εξαιρεί τον
/// εαυτό του· ίδιο normalized με τον εαυτό = no-op επιτυχία χωρίς write.
/// Το create ΔΕΝ επιλέγει στη φόρμα (διαφορά από το
/// `ReceiptFormController.createSupplier` — σκόπιμο non-reuse, διαφορετικό
/// contract: εδώ `(ok, error)`, εκεί `{supplier, created}` + select).
///
/// Διαγραφή: RESTRICT (§3) — ΜΟΝΟ καθαρός (`countBySupplierId == 0`, πύλη +
/// defense in depth)· αν ο σβησμένος ήταν επιλεγμένος σε ανοιχτό draft,
/// μηδενίζεται η επιλογή (`setSupplier(null)` — αλλιώς το save θα έσκαγε
/// σε FK, οι γραμμές-draft δεν φαίνονται στην πύλη).
///
/// Σφάλματα: validation/dup → record `(ok:false, error:)` (snackbar από το
/// widget, pattern `_createSupplier`)· DB → `DataLoadException` ανέγγιχτο
/// (λογκαρισμένο μία φορά στον DAO guard, feedback στο widget).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/greek_text_normalizer.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../../price_entry/controllers/receipt_form_controller.dart';
import '../state/settings_state.dart';

/// SPoT provider διαχείρισης προμηθευτών — μη autoDispose (§2.2:221).
final supplierManagementControllerProvider =
    NotifierProvider<SupplierManagementController, SettingsState>(
      SupplierManagementController.new,
    );

/// Controller CRUD προμηθευτών (supplier list editor §2.3).
class SupplierManagementController extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  /// Εκτελεί [op] με `isWorking` guard: επανείσοδος ενώ τρέχει → no-op
  /// `(ok:false, error:null)` (double-tap guard, §2.4). Το flag σβήνει ΠΑΝΤΑ
  /// (finally) — αλλιώς τα κουμπιά μένουν ανενεργά για πάντα.
  Future<({bool ok, String? error})> _guarded(
    Future<({bool ok, String? error})> Function() op,
  ) async {
    if (state.isWorking) return (ok: false, error: null);
    state = state.copyWith(isWorking: true);
    try {
      return await op();
    } finally {
      if (ref.mounted) state = state.copyWith(isWorking: false);
    }
  }

  /// Δημιουργεί προμηθευτή. Validation/dup → `(ok:false, error:)` χωρίς DB
  /// access· επιτυχία → `(ok:true)` + log. DB σφάλμα → `DataLoadException`.
  /// ΔΕΝ επιλέγει στη φόρμα (διαφορά από το header §2.4).
  Future<({bool ok, String? error})> createSupplier(String name) =>
      _guarded(() async {
        final trimmed = name.trim();
        if (NameValidator.validate(trimmed) != null) {
          return (ok: false, error: NameValidator.validate(trimmed));
        }
        final repo = ref.read(supplierRepositoryProvider);
        final existing = await repo.getByNormalizedName(
          GreekTextNormalizer.normalize(trimmed),
        );
        if (existing != null) {
          AppLogger.info(
            LogTag.ui,
            'Απόρριψη «+» προμηθευτή "$trimmed": διπλότυπο',
          );
          return (ok: false, error: AppErrors.nameExists);
        }
        final id = await repo.insert(name: trimmed);
        AppLogger.info(LogTag.db, 'Δημιουργία προμηθευτή: $trimmed (#$id)');
        return (ok: true, error: null);
      });

  /// Μετονομάζει προμηθευτή. Ίδιο normalized με τον εαυτό → no-op επιτυχία
  /// (χωρίς write). Dup προς άλλον → `nameExists`. Ανύπαρκτο id →
  /// `loadDataFailed` (η λίστα ανανεώθηκε ενδιάμεσα — race §2.3). Οι
  /// αποδείξεις δείχνουν το νέο όνομα αυτόματα (join, §2.2 Βήμα 7).
  Future<({bool ok, String? error})> renameSupplier(int id, String name) =>
      _guarded(() async {
        final trimmed = name.trim();
        final validationError = NameValidator.validate(trimmed);
        if (validationError != null) {
          return (ok: false, error: validationError);
        }
        final repo = ref.read(supplierRepositoryProvider);
        final current = await repo.getById(id);
        if (current == null) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        if (NameValidator.isDuplicate(trimmed, [current.name])) {
          return (ok: true, error: null); // no-op — κανένα write
        }
        final clash = await repo.getByNormalizedName(
          GreekTextNormalizer.normalize(trimmed),
        );
        if (clash != null) {
          AppLogger.info(
            LogTag.ui,
            'Απόρριψη μετονομασίας προμηθευτή #$id σε "$trimmed": διπλότυπο',
          );
          return (ok: false, error: AppErrors.nameExists);
        }
        await repo.updateById(id, name: trimmed);
        AppLogger.info(LogTag.db, 'Μετονομασία προμηθευτή #$id: $trimmed');
        return (ok: true, error: null);
      });

  /// Διαγράφει καθαρό προμηθευτή (0 αποδείξεις). Ελέγχει ο ΙΔΙΟΣ την πύλη
  /// (`countBySupplierId == 0`) — defense in depth πέρα από το greyed-out UI·
  /// μπλοκαρισμένος → `supplierReceiptsTooltip`. Μετά το delete αποδεσμεύει
  /// το family cache του id + μηδενίζει τυχόν draft-επιλογή του.
  Future<({bool ok, String? error})> deleteSupplier(int id) =>
      _guarded(() async {
        final receiptRepo = ref.read(receiptRepositoryProvider);
        final count = await receiptRepo.countBySupplierId(id);
        if (count > 0) {
          return (ok: false, error: AppMessages.supplierReceiptsTooltip(count));
        }
        final deleted =
            await ref.read(supplierRepositoryProvider).deleteById(id);
        if (!deleted) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        ref.invalidate(canDeleteSupplierProvider(id));
        ref.invalidate(receiptCountSupplierProvider(id));
        // Draft-επιλογή του σβησμένου → αποεπιλογή (οι draft γραμμές δεν
        // φαίνονται στην πύλη· αλλιώς το save θα έσκαγε σε FK).
        final form = ref.read(receiptFormControllerProvider);
        if (form.supplier?.id == id) {
          ref.read(receiptFormControllerProvider.notifier).setSupplier(null);
          AppLogger.info(
            LogTag.ui,
            'Αποεπιλογή σβησμένου προμηθευτή #$id από το draft',
          );
        }
        AppLogger.info(LogTag.db, 'Διαγραφή προμηθευτή #$id');
        return (ok: true, error: null);
      });

  /// Ανανέωση ΟΛΩΝ των ορατών πυλών (stale one-shot bools, IndexedStack):
  /// το PriceEntry προσθέτει αποδείξεις χωρίς να ξανατρέχουν τα families.
  /// Καλείται από το κουμπί ανανέωσης με τα ids της τρέχουσας λίστας.
  void refreshGuards({required Iterable<int> supplierIds}) {
    for (final id in supplierIds) {
      ref.invalidate(canDeleteSupplierProvider(id));
      ref.invalidate(receiptCountSupplierProvider(id));
    }
    AppLogger.info(LogTag.ui, 'Ανανέωση ελέγχων διαγραφής προμηθευτών');
  }
}
