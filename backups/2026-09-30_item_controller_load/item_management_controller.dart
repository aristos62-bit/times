/// Controller διαχείρισης ειδών (§2.3 DESIGN / ενότητα Ειδών).
///
/// Plain `Notifier<SettingsState>` (όχι AsyncNotifier): το state είναι
/// σύγχρονο (μόνο `isWorking` flag)· η αναζήτηση έρχεται από το forked
/// `itemSearchControllerProvider` (override, §2.4) και η πύλη από τους
/// `canDeleteItemProvider` / `itemLinesCountProvider`. Pattern
/// `SupplierManagementController` (σύγχρονο state + async actions με flag).
/// NON-autoDispose (§2.2:221, IndexedStack).
///
/// Η δημιουργία ΔΕΝ ζει εδώ — γίνεται στο `NewItemFlowDialog` (reuse §2.4)
/// μέσω του forked search controller, όπως στο `ItemSearchField`.
/// Dup-check exact (`getByNormalizedName` — ο πίνακας Item ΕΧΕΙ UNIQUE
/// `normalizedName`, §3). Το rename εξαιρεί τον εαυτό του· ίδιο normalized
/// με τον εαυτό = no-op επιτυχία χωρίς write.
///
/// Διαγραφή: RESTRICT (§3) — ΜΟΝΟ καθαρό (`countLinesByItemId == 0`, πύλη +
/// defense in depth)· αν το σβησμένο ήταν επιλεγμένο (root ή fork),
/// αποεπιλέγεται (αλλιώς lifeline με νεκρό id).
///
/// Σφάλματα: validation/dup → record `(ok:false, error:)` (snackbar από το
/// widget, pattern `_createSupplier`)· DB → `DataLoadException` ανέγγιχτο
/// (λογκαρισμένο μία φορά στον DAO guard, feedback στο widget).
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/greek_text_normalizer.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../../price_entry/controllers/item_search_controller.dart';
import '../state/settings_state.dart';

/// SPoT provider διαχείρισης ειδών — μη autoDispose (§2.2:221).
final itemManagementControllerProvider =
    NotifierProvider<ItemManagementController, SettingsState>(
      ItemManagementController.new,
    );

/// Controller CRUD ειδών (item list editor §2.3).
class ItemManagementController extends Notifier<SettingsState> {
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

  /// Ενημερώνει είδος (όνομα/τμήμα/προτεινόμενη μονάδα). Validation/
  /// dup → `(ok:false, error:)` χωρίς DB access· καμία αλλαγή → no-op
  /// επιτυχία (χωρίς write)· ανύπαρκτο id → `loadDataFailed` (race §2.3).
  /// Μετά το write ανανεώνει τις πύλες παλιού + νέου τμήματος/υποκατηγορίας/
  /// κατηγορίας (η μετακίνηση αλλάζει τα `inUse` counts — §2.3:299).
  Future<({bool ok, String? error})> updateItem({
    required int id,
    required String name,
    required int itemGroupId,
    Value<int?>? defaultUnitId,
  }) =>
      _guarded(() async {
        final trimmed = name.trim();
        final validationError = NameValidator.validate(trimmed);
        if (validationError != null) {
          return (ok: false, error: validationError);
        }
        final repo = ref.read(itemRepositoryProvider);
        final current = await repo.getById(id);
        if (current == null) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        if (trimmed == current.name &&
            itemGroupId == current.itemGroupId &&
            _sameUnit(defaultUnitId, current.defaultUnitId)) {
          return (ok: true, error: null); // no-op — καμία αλλαγή
        }
        final clash = await repo.getByNormalizedName(
          GreekTextNormalizer.normalize(trimmed),
        );
        if (clash != null && clash.id != id) {
          AppLogger.info(
            LogTag.ui,
            'Απόρριψη μετονομασίας είδους #$id σε "$trimmed": διπλότυπο',
          );
          return (ok: false, error: AppErrors.nameExists);
        }
        final updated = await repo.updateById(
          id,
          name: trimmed,
          itemGroupId: itemGroupId,
          defaultUnitId: defaultUnitId,
        );
        if (!updated) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        await _refreshItemGuards(
          itemId: id,
          itemGroupIds: {current.itemGroupId, itemGroupId},
        );
        AppLogger.info(LogTag.db, 'Ενημέρωση είδους #$id: $trimmed');
        return (ok: true, error: null);
      });

  /// Διαγράφει καθαρό είδος (0 γραμμές). Ελέγχει ο ΙΔΙΟΣ την πύλη
  /// (`countLinesByItemId == 0`) — defense in depth· μπλοκαρισμένο →
  /// `itemLinesTooltip`. Μετά το delete αποδεσμεύει τα families + καθαρίζει
  /// τυχόν επιλογή του (root search — οι draft γραμμές δεν φαίνονται).
  Future<({bool ok, String? error})> deleteItem(int id) =>
      _guarded(() async {
        final receiptRepo = ref.read(receiptRepositoryProvider);
        final lines = await receiptRepo.countLinesByItemId(id);
        if (lines > 0) {
          return (ok: false, error: AppMessages.itemLinesTooltip(lines));
        }
        final item = await ref.read(itemRepositoryProvider).getById(id);
        final deleted = await ref.read(itemRepositoryProvider).deleteById(id);
        if (!deleted) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        ref.invalidate(canDeleteItemProvider(id));
        ref.invalidate(itemLinesCountProvider(id));
        if (item != null) {
          await _refreshGuardsForGroups({item.itemGroupId});
        }
        // Επιλογή του σβησμένου στο root search → αποεπιλογή.
        final search = ref.read(itemSearchControllerProvider);
        if (search.value?.selectedItem?.id == id) {
          ref.read(itemSearchControllerProvider.notifier).clearSelection();
          AppLogger.info(
            LogTag.ui,
            'Αποεπιλογή σβησμένου είδους #$id από την αναζήτηση',
          );
        }
        AppLogger.info(LogTag.db, 'Διαγραφή είδους #$id');
        return (ok: true, error: null);
      });

  /// Ανανέωση ορατών πυλών είδους (stale one-shot, IndexedStack).
  void refreshGuards({required Iterable<int> itemIds}) {
    for (final id in itemIds) {
      ref.invalidate(canDeleteItemProvider(id));
      ref.invalidate(itemLinesCountProvider(id));
    }
    AppLogger.info(LogTag.ui, 'Ανανέωση ελέγχων διαγραφής ειδών');
  }

  /// Ίδια μονάδα; `null`/absent = «μην πειράξεις» → ίδιο· αλλιώς σύγκριση
  /// τιμής με την τρέχουσα (nullable — `Value(null)` = καθάρισμα).
  bool _sameUnit(Value<int?>? requested, int? current) {
    if (requested == null || !requested.present) return true;
    return requested.value == current;
  }

  /// Ανανέωση πυλών είδους + τμημάτων/υποκατηγοριών/κατηγοριών που το
  /// περιέχουν (27-09-2026, 4 επίπεδα).
  Future<void> _refreshItemGuards({
    required int itemId,
    required Set<int> itemGroupIds,
  }) async {
    ref.invalidate(canDeleteItemProvider(itemId));
    ref.invalidate(itemLinesCountProvider(itemId));
    await _refreshGuardsForGroups(itemGroupIds);
  }

  /// Invalidate `canDelete*/inUseCount*` για τμήματα + γονικές
  /// υποκατηγορίες + κατηγορίες (οι μετρήσεις τους αλλάζουν σε
  /// move/delete είδους).
  Future<void> _refreshGuardsForGroups(Set<int> itemGroupIds) async {
    final groupRepo = ref.read(itemGroupRepositoryProvider);
    final subRepo = ref.read(subCategoryRepositoryProvider);
    for (final groupId in itemGroupIds) {
      if (!ref.mounted) return;
      ref.invalidate(canDeleteItemGroupProvider(groupId));
      ref.invalidate(inUseCountItemGroupProvider(groupId));
      final group = await groupRepo.getById(groupId);
      if (group == null) continue;
      if (!ref.mounted) return;
      ref.invalidate(canDeleteSubCategoryProvider(group.subCategoryId));
      ref.invalidate(inUseCountSubCategoryProvider(group.subCategoryId));
      final sub = await subRepo.getById(group.subCategoryId);
      if (sub == null) continue;
      if (!ref.mounted) return;
      ref.invalidate(canDeleteCategoryProvider(sub.categoryId));
      ref.invalidate(inUseCountCategoryProvider(sub.categoryId));
    }
  }
}
