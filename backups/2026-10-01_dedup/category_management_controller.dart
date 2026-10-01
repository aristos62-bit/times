/// Controller διαχείρισης καταλόγου 4 επιπέδων (§2.3 DESIGN · 27-09-2026).
///
/// Plain `Notifier<SettingsState>` (όχι AsyncNotifier): το state είναι
/// σύγχρονο (μόνο `isWorking` flag)· το δέντρο έρχεται από τον
/// `categoryTreeStreamProvider` και οι πύλες από τους `canDelete*` providers.
/// Pattern `ReceiptFormController` (σύγχρονο state + async actions με flag).
/// NON-autoDispose (§2.2:221, IndexedStack).
///
/// Dup-check exact-match (`getByNormalizedName` — όλοι οι πίνακες καταλόγου
/// ΕΧΟΥΝ UNIQUE `normalizedName`, §3 27-09-2026). Το rename εξαιρεί τον εαυτό
/// του (recase επιτρέπεται)· clash με άλλον → `nameExists`.
///
/// Σφάλματα: validation/dup → record `(ok:false, error:)` (inline/snackbar
/// από το widget)· DB → `DataLoadException` ανέγγιχτο (λογκαρισμένο μία
/// φορά στον DAO guard, feedback στο widget).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_errors.dart';
import '../../../core/constants/app_messages.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/greek_text_normalizer.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../domain/validators/name_validator.dart';
import '../state/settings_state.dart';

/// SPoT provider διαχείρισης καταλόγου — μη autoDispose (§2.2:221).
final categoryManagementControllerProvider =
    NotifierProvider<CategoryManagementController, SettingsState>(
      CategoryManagementController.new,
    );

/// Controller CRUD κατηγοριών/υποκατηγοριών/τμημάτων (tree editor §2.3).
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

  /// Δημιουργεί κατηγορία. Validation/dup → `(ok:false, error:)` χωρίς
  /// περιττό write· επιτυχία → `(ok:true)` + log. DB σφάλμα → rethrow.
  Future<({bool ok, String? error})> createCategory(String name) =>
      _guarded(() async {
        final trimmed = name.trim();
        if (NameValidator.validate(trimmed) != null) {
          return (ok: false, error: NameValidator.validate(trimmed));
        }
        final repo = ref.read(categoryRepositoryProvider);
        final clash = await repo.getByNormalizedName(
          GreekTextNormalizer.normalize(trimmed),
        );
        if (clash != null) {
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

  /// Μετονομάζει κατηγορία. Ίδιο normalized με τον εαυτό → write (recase
  /// επιτρέπεται)· clash με άλλον → `nameExists`. Ανύπαρκτο id →
  /// `loadDataFailed` (race §2.3).
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
        final clash = await repo.getByNormalizedName(
          GreekTextNormalizer.normalize(trimmed),
        );
        if (clash != null && clash.id != id) {
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

  /// Δημιουργεί υποκατηγορία στην [categoryId] (exact-match dup-check).
  Future<({bool ok, String? error})> createSubCategory({
    required int categoryId,
    required String name,
  }) => _guarded(() async {
    final trimmed = name.trim();
    if (NameValidator.validate(trimmed) != null) {
      return (ok: false, error: NameValidator.validate(trimmed));
    }
    final repo = ref.read(subCategoryRepositoryProvider);
    final clash = await repo.getByNormalizedName(
      GreekTextNormalizer.normalize(trimmed),
    );
    if (clash != null) {
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

  /// Μετονομάζει υποκατηγορία (χωρίς αλλαγή κατηγορίας — εκτός scope).
  /// Recase επιτρέπεται· clash με άλλον → `nameExists`.
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
        final clash = await repo.getByNormalizedName(
          GreekTextNormalizer.normalize(trimmed),
        );
        if (clash != null && clash.id != id) {
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

  /// Διαγράφει υποκατηγορία με τμήματα + ορφανά είδη (cascade, §2.3 Α/Γ).
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

  /// Δημιουργεί τμήμα στην [subCategoryId] (27-09-2026 · exact-match).
  Future<({bool ok, String? error})> createItemGroup({
    required int subCategoryId,
    required String name,
  }) => _guarded(() async {
    final trimmed = name.trim();
    if (NameValidator.validate(trimmed) != null) {
      return (ok: false, error: NameValidator.validate(trimmed));
    }
    final repo = ref.read(itemGroupRepositoryProvider);
    final clash = await repo.getByNormalizedName(
      GreekTextNormalizer.normalize(trimmed),
    );
    if (clash != null) {
      AppLogger.info(
        LogTag.ui,
        'Απόρριψη «+» τμήματος "$trimmed": διπλότυπο',
      );
      return (ok: false, error: AppErrors.nameExists);
    }
    final id = await repo.insert(subCategoryId: subCategoryId, name: trimmed);
    AppLogger.info(
      LogTag.db,
      'Δημιουργία τμήματος: $trimmed (#$id, sub #$subCategoryId)',
    );
    return (ok: true, error: null);
  });

  /// Μετονομάζει τμήμα (χωρίς αλλαγή υποκατηγορίας). Recase επιτρέπεται.
  Future<({bool ok, String? error})> renameItemGroup(int id, String name) =>
      _guarded(() async {
        final trimmed = name.trim();
        final validationError = NameValidator.validate(trimmed);
        if (validationError != null) {
          return (ok: false, error: validationError);
        }
        final repo = ref.read(itemGroupRepositoryProvider);
        final current = await repo.getById(id);
        if (current == null) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        if (trimmed == current.name) {
          return (ok: true, error: null); // no-op — ακριβώς ίδιο κείμενο
        }
        final clash = await repo.getByNormalizedName(
          GreekTextNormalizer.normalize(trimmed),
        );
        if (clash != null && clash.id != id) {
          AppLogger.info(
            LogTag.ui,
            'Απόρριψη μετονομασίας τμήματος #$id σε "$trimmed": διπλότυπο',
          );
          return (ok: false, error: AppErrors.nameExists);
        }
        await repo.updateById(id, name: trimmed);
        AppLogger.info(LogTag.db, 'Μετονομασία τμήματος #$id: $trimmed');
        return (ok: true, error: null);
      });

  /// Διαγράφει τμήμα με τα ορφανά είδη του (cascade, §2.3 Α/Γ).
  Future<({bool ok, String? error})> deleteItemGroup(int id) =>
      _guarded(() async {
        final repo = ref.read(itemGroupRepositoryProvider);
        final inUse = await repo.countItemsInUse(id);
        if (inUse > 0) {
          return (ok: false, error: AppMessages.itemsInUseTooltip(inUse));
        }
        final deleted = await repo.deleteWithContents(id);
        if (!deleted) {
          return (ok: false, error: AppErrors.loadDataFailed);
        }
        ref.invalidate(canDeleteItemGroupProvider(id));
        ref.invalidate(inUseCountItemGroupProvider(id));
        AppLogger.info(LogTag.db, 'Διαγραφή τμήματος #$id (cascade)');
        return (ok: true, error: null);
      });

  /// Σύνολο ειδών κατηγορίας για το cascade confirm («θα σβηστούν Ν είδη»).
  /// One-shot την ώρα του tap — DB σφάλμα → `DataLoadException`.
  Future<int> getCategoryItemCount(int categoryId) =>
      ref.read(categoryRepositoryProvider).countItems(categoryId);

  /// Σύνολο ειδών υποκατηγορίας για το cascade confirm.
  Future<int> getSubCategoryItemCount(int subCategoryId) =>
      ref.read(subCategoryRepositoryProvider).countItems(subCategoryId);

  /// Σύνολο ειδών τμήματος για το cascade confirm (27-09-2026).
  Future<int> getItemGroupItemCount(int itemGroupId) =>
      ref.read(itemGroupRepositoryProvider).countItems(itemGroupId);

  /// Ανανέωση ΟΛΩΝ των ορατών πυλών (stale one-shot bools, IndexedStack).
  /// Καλείται από το κουμπί ανανέωσης με τα ids του τρέχοντος δέντρου.
  void refreshGuards({
    required Iterable<int> categoryIds,
    required Iterable<int> subCategoryIds,
    required Iterable<int> itemGroupIds,
  }) {
    for (final id in categoryIds) {
      ref.invalidate(canDeleteCategoryProvider(id));
      ref.invalidate(inUseCountCategoryProvider(id));
    }
    for (final id in subCategoryIds) {
      ref.invalidate(canDeleteSubCategoryProvider(id));
      ref.invalidate(inUseCountSubCategoryProvider(id));
    }
    for (final id in itemGroupIds) {
      ref.invalidate(canDeleteItemGroupProvider(id));
      ref.invalidate(inUseCountItemGroupProvider(id));
    }
    AppLogger.info(LogTag.ui, 'Ανανέωση ελέγχων διαγραφής καταλόγου');
  }
}
