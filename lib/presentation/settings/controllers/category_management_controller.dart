/// Controller διαχείρισης κατηγοριών/υποκατηγοριών (§2.3 DESIGN /
/// Φάση 4 Βήμα 4).
///
/// Plain `Notifier<SettingsState>` (όχι AsyncNotifier): το state είναι
/// σύγχρονο (μόνο `isWorking` flag)· το δέντρο έρχεται από τον
/// `categoryTreeStreamProvider` και η πύλη από τους `canDelete* providers.
/// Pattern `ReceiptFormController` (σύγχρονο state + async actions με flag).
/// NON-autoDispose (§2.2:221, IndexedStack).
///
/// Dup-check in-memory (`watchAll().first` / `watchByCategoryId().first` +
/// `NameValidator.isDuplicate`) — οι πίνακες Category/SubCategory ΔΕΝ έχουν
/// UNIQUE στήλη (`tables.dart`), άρα δεν υπάρχει `getByNormalizedName`
/// (pattern `ItemSearchController.createCategory`, όχι reuse του instance —
/// λάθος lifecycle/οθόνη). Το rename εξαιρεί τον εαυτό του· ίδιο normalized
/// με τον εαυτό = no-op επιτυχία χωρίς write.
///
/// Σφάλματα: validation/dup → record `(ok:false, error:)` (inline/snackbar
/// από το widget, pattern `_createSupplier`)· DB → `DataLoadException`
/// ανέγγιχτο (λογκαρισμένο μία φορά στον DAO guard, feedback στο widget).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../state/settings_state.dart';

/// SPoT provider διαχείρισης καταλόγου — μη autoDispose (§2.2:221).
final categoryManagementControllerProvider =
    NotifierProvider<CategoryManagementController, SettingsState>(
      CategoryManagementController.new,
    );

/// Controller CRUD κατηγοριών/υποκατηγοριών (tree editor §2.3 · Βήμα 4).
class CategoryManagementController extends Notifier<SettingsState> {
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

  /// Δημιουργεί κατηγορία. Validation/dup → `(ok:false, error:)` χωρίς DB
  /// access· επιτυχία → `(ok:true)` + log. DB σφάλμα → `DataLoadException`.
  Future<({bool ok, String? error})> createCategory(String name) =>
      _guarded(() async {
        final trimmed = name.trim();
        if (NameValidator.validate(trimmed) != null) {
          return (ok: false, error: NameValidator.validate(trimmed));
        }
        final repo = ref.read(categoryRepositoryProvider);
        final existing = await repo.watchAll().first;
        if (NameValidator.isDuplicate(trimmed, existing.map((c) => c.name))) {
          AppLogger.info(
            LogTag.ui,
            'Απόρριψη «+» κατηγορίας "$trimmed": διπλότυπο',
          );
          return (ok: false, error: AppErrors.nameExists);
        }
        final id = await repo.insert(name: trimmed);
        AppLogger.info(LogTag.db, 'Δημιουργία κατηγορίας: $trimmed (#$id)');
        return (ok: true, error: null);
      });

  /// Μετονομάζει κατηγορία. Ακριβώς ίδιο κείμενο → no-op επιτυχία
  /// (χωρίς write)· αλλαγή μόνο πεζών/τόνων ΓΡΑΦΕΤΑΙ (24-09-2026 — τα seed
  /// είναι κεφαλαία). Dup προς αδελφό → `nameExists`. Ανύπαρκτο id →
  /// `loadDataFailed` (το δέντρο ανανεώθηκε ενδιάμεσα — race §2.3).
  Future<({bool ok, String? error})> renameCategory(int id, String name) =>
      _guarded(() async {
        final trimmed = name.trim();
        final validationError = NameValidator.validate(trimmed);
        if (validationError != null) {
          return (ok: false, error: validationError);
        }
        final repo = ref.read(categoryRepositoryProvider);
        final current = await repo.getById(id);
        if (current == null) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        if (trimmed == current.name) {
          return (ok: true, error: null); // no-op — ακριβώς ίδιο κείμενο
        }
        final existing = await repo.watchAll().first;
        if (NameValidator.isDuplicate(
          trimmed,
          existing.where((c) => c.id != id).map((c) => c.name),
        )) {
          AppLogger.info(
            LogTag.ui,
            'Απόρριψη μετονομασίας κατηγορίας #$id σε "$trimmed": διπλότυπο',
          );
          return (ok: false, error: AppErrors.nameExists);
        }
        await repo.updateById(id, name: trimmed);
        AppLogger.info(LogTag.db, 'Μετονομασία κατηγορίας #$id: $trimmed');
        return (ok: true, error: null);
      });

  /// Διαγράφει κατηγορία με το περιεχόμενό της (cascade, §2.3 Α/Γ).
  /// Ελέγχει ο ΙΔΙΟΣ την πύλη (`countItemsInUse == 0`) — defense in depth
  /// πέρα από το greyed-out UI· μπλοκαρισμένη → `itemsInUseTooltip`.
  /// Μετά το delete αποδεσμεύει το family cache του id (canDelete+inUse).
  Future<({bool ok, String? error})> deleteCategory(int id) =>
      _guarded(() async {
        final repo = ref.read(categoryRepositoryProvider);
        final inUse = await repo.countItemsInUse(id);
        if (inUse > 0) {
          return (ok: false, error: AppMessages.itemsInUseTooltip(inUse));
        }
        final deleted = await repo.deleteWithContents(id);
        if (!deleted) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        ref.invalidate(canDeleteCategoryProvider(id));
        ref.invalidate(inUseCountCategoryProvider(id));
        AppLogger.info(LogTag.db, 'Διαγραφή κατηγορίας #$id (cascade)');
        return (ok: true, error: null);
      });

  /// Δημιουργεί υποκατηγορία στην [categoryId]. Dup-check εντός της
  /// κατηγορίας (in-memory, scope Βήματος 4 — όχι global).
  Future<({bool ok, String? error})> createSubCategory({
    required int categoryId,
    required String name,
  }) => _guarded(() async {
    final trimmed = name.trim();
    if (NameValidator.validate(trimmed) != null) {
      return (ok: false, error: NameValidator.validate(trimmed));
    }
    final repo = ref.read(subCategoryRepositoryProvider);
    final existing = await repo.watchByCategoryId(categoryId).first;
    if (NameValidator.isDuplicate(trimmed, existing.map((s) => s.name))) {
      AppLogger.info(
        LogTag.ui,
        'Απόρριψη «+» υποκατηγορίας "$trimmed": διπλότυπο',
      );
      return (ok: false, error: AppErrors.nameExists);
    }
    final id = await repo.insert(categoryId: categoryId, name: trimmed);
    AppLogger.info(
      LogTag.db,
      'Δημιουργία υποκατηγορίας: $trimmed (#$id, cat #$categoryId)',
    );
    return (ok: true, error: null);
  });

  /// Μετονομάζει υποκατηγορία (χωρίς αλλαγή κατηγορίας — καμία μετακίνηση,
  /// εκτός scope Βήματος 4). Ακριβώς ίδιο κείμενο → no-op (24-09-2026).
  /// Dup-check εντός της ίδιας κατηγορίας.
  Future<({bool ok, String? error})> renameSubCategory(int id, String name) =>
      _guarded(() async {
        final trimmed = name.trim();
        final validationError = NameValidator.validate(trimmed);
        if (validationError != null) {
          return (ok: false, error: validationError);
        }
        final repo = ref.read(subCategoryRepositoryProvider);
        final current = await repo.getById(id);
        if (current == null) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        if (trimmed == current.name) {
          return (ok: true, error: null); // no-op — ακριβώς ίδιο κείμενο
        }
        final siblings = await repo
            .watchByCategoryId(current.categoryId)
            .first;
        if (NameValidator.isDuplicate(
          trimmed,
          siblings.where((s) => s.id != id).map((s) => s.name),
        )) {
          AppLogger.info(
            LogTag.ui,
            'Απόρριψη μετονομασίας υποκατηγορίας #$id σε "$trimmed": διπλότυπο',
          );
          return (ok: false, error: AppErrors.nameExists);
        }
        await repo.updateById(id, name: trimmed);
        AppLogger.info(LogTag.db, 'Μετονομασία υποκατηγορίας #$id: $trimmed');
        return (ok: true, error: null);
      });

  /// Διαγράφει υποκατηγορία με τα ορφανά είδη της (cascade, §2.3 Α/Γ).
  /// Ίδια πύλη + cache-αποδέσμευση με την κατηγορία.
  Future<({bool ok, String? error})> deleteSubCategory(int id) =>
      _guarded(() async {
        final repo = ref.read(subCategoryRepositoryProvider);
        final inUse = await repo.countItemsInUse(id);
        if (inUse > 0) {
          return (ok: false, error: AppMessages.itemsInUseTooltip(inUse));
        }
        final deleted = await repo.deleteWithContents(id);
        if (!deleted) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        ref.invalidate(canDeleteSubCategoryProvider(id));
        ref.invalidate(inUseCountSubCategoryProvider(id));
        AppLogger.info(LogTag.db, 'Διαγραφή υποκατηγορίας #$id (cascade)');
        return (ok: true, error: null);
      });

  /// Σύνολο ειδών κατηγορίας για το cascade confirm («θα σβηστούν Ν είδη»).
  /// One-shot την ώρα του tap — όχι provider (Βήμα 4, Δ1 επανελέγχου).
  /// DB σφάλμα → `DataLoadException` (widget δείχνει `loadDataFailed`).
  Future<int> getCategoryItemCount(int categoryId) =>
      ref.read(categoryRepositoryProvider).countItems(categoryId);

  /// Σύνολο ειδών υποκατηγορίας για το cascade confirm.
  Future<int> getSubCategoryItemCount(int subCategoryId) =>
      ref.read(subCategoryRepositoryProvider).countItems(subCategoryId);

  /// Ανανέωση ΟΛΩΝ των ορατών πυλών (stale one-shot bools, IndexedStack):
  /// το PriceEntry προσθέτει γραμμές χωρίς να ξανατρέχουν τα families.
  /// Καλείται από το κουμπί ανανέωσης με τα ids του τρέχοντος δέντρου.
  void refreshGuards({
    required Iterable<int> categoryIds,
    required Iterable<int> subCategoryIds,
  }) {
    for (final id in categoryIds) {
      ref.invalidate(canDeleteCategoryProvider(id));
      ref.invalidate(inUseCountCategoryProvider(id));
    }
    for (final id in subCategoryIds) {
      ref.invalidate(canDeleteSubCategoryProvider(id));
      ref.invalidate(inUseCountSubCategoryProvider(id));
    }
    AppLogger.info(LogTag.ui, 'Ανανέωση ελέγχων διαγραφής καταλόγου');
  }
}
