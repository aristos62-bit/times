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

  /// Generic δημιουργίας (01-10): trim → validate (μία κλήση) →
  /// dup-check → insert → logs. Οι διαφορές επιπέδων κρύβονται σε closures
  /// (repos/strings/payloads) — οι 3 public μέθοδοι μένουν λεπτά wrappers.
  Future<({bool ok, String? error})> _create({
    required String name,
    required Future<Object?> Function(String normalized) findClash,
    required Future<int> Function(String trimmed) insert,
    required String Function(String trimmed) dupLog,
    required String Function(String trimmed, int id) okLog,
  }) => _guarded(() async {
    final trimmed = name.trim();
    final validationError = NameValidator.validate(trimmed);
    if (validationError != null) {
      return (ok: false, error: validationError);
    }
    final clash = await findClash(GreekTextNormalizer.normalize(trimmed));
    if (clash != null) {
      AppLogger.info(LogTag.ui, dupLog(trimmed));
      return (ok: false, error: AppErrors.nameExists);
    }
    final id = await insert(trimmed);
    AppLogger.info(LogTag.db, okLog(trimmed, id));
    return (ok: true, error: null);
  });

  /// Generic μετονομασίας (01-10): trim → validate → load → no-op →
  /// dup-check (εξαίρεση εαυτού) → update → logs. Records ως δομική κόλλα
  /// (όχι shared interfaces — μηδέν αλλαγές repos).
  Future<({bool ok, String? error})> _rename({
    required int id,
    required String name,
    required Future<({int id, String name})?> Function(int id) load,
    required Future<({int id})?> Function(String normalized) findClash,
    required Future<void> Function(int id, String trimmed) save,
    required String Function(int id, String trimmed) dupLog,
    required String Function(int id, String trimmed) okLog,
  }) => _guarded(() async {
    final trimmed = name.trim();
    final validationError = NameValidator.validate(trimmed);
    if (validationError != null) {
      return (ok: false, error: validationError);
    }
    final current = await load(id);
    if (current == null) {
      return (ok: false, error: AppErrors.loadDataFailed);
    }
    if (trimmed == current.name) {
      return (ok: true, error: null); // no-op — ακριβώς ίδιο κείμενο
    }
    final clash = await findClash(GreekTextNormalizer.normalize(trimmed));
    if (clash != null && clash.id != id) {
      AppLogger.info(LogTag.ui, dupLog(id, trimmed));
      return (ok: false, error: AppErrors.nameExists);
    }
    await save(id, trimmed);
    AppLogger.info(LogTag.db, okLog(id, trimmed));
    return (ok: true, error: null);
  });

  /// Generic διαγραφής (01-10): πύλη (defense in depth) → cascade →
  /// invalidate πύλες → log. Το blocked μήνυμα είναι κοινό
  /// (`itemsInUseTooltip`) — μόνο τα invalidates περνάνε ως callback.
  Future<({bool ok, String? error})> _delete({
    required int id,
    required Future<int> Function(int id) countInUse,
    required Future<bool> Function(int id) remove,
    required void Function(int id) invalidateGuards,
    required String okLog,
  }) => _guarded(() async {
    final inUse = await countInUse(id);
    if (inUse > 0) {
      return (ok: false, error: AppMessages.itemsInUseTooltip(inUse));
    }
    final deleted = await remove(id);
    if (!deleted) {
      return (ok: false, error: AppErrors.loadDataFailed);
    }
    invalidateGuards(id);
    AppLogger.info(LogTag.db, '$okLog #$id (cascade)');
    return (ok: true, error: null);
  });

  /// Δημιουργεί κατηγορία. Validation/dup → `(ok:false, error:)` χωρίς
  /// περιττό write· επιτυχία → `(ok:true)` + log. DB σφάλμα → rethrow.
  Future<({bool ok, String? error})> createCategory(String name) {
    final repo = ref.read(categoryRepositoryProvider);
    return _create(
      name: name,
      findClash: repo.getByNormalizedName,
      insert: (trimmed) => repo.insert(name: trimmed),
      dupLog: (t) => 'Απόρριψη «+» κατηγορίας "$t": διπλότυπο',
      okLog: (t, id) => 'Δημιουργία κατηγορίας: $t (#$id)',
    );
  }

  /// Μετονομάζει κατηγορία. Ίδιο normalized με τον εαυτό → write (recase
  /// επιτρέπεται)· clash με άλλον → `nameExists`. Ανύπαρκτο id →
  /// `loadDataFailed` (race §2.3).
  Future<({bool ok, String? error})> renameCategory(int id, String name) {
    final repo = ref.read(categoryRepositoryProvider);
    return _rename(
      id: id,
      name: name,
      load: (id) async {
        final c = await repo.getById(id);
        return c == null ? null : (id: c.id, name: c.name);
      },
      findClash: (n) async {
        final c = await repo.getByNormalizedName(n);
        return c == null ? null : (id: c.id);
      },
      save: (id, trimmed) async {
        await repo.updateById(id, name: trimmed);
      },
      dupLog: (id, t) =>
          'Απόρριψη μετονομασίας κατηγορίας #$id σε "$t": διπλότυπο',
      okLog: (id, t) => 'Μετονομασία κατηγορίας #$id: $t',
    );
  }

  /// Διαγράφει κατηγορία με το περιεχόμενό της (cascade, §2.3 Α/Γ).
  /// Ελέγχει ο ΙΔΙΟΣ την πύλη (`countItemsInUse == 0`) — defense in depth
  /// πέρα από το greyed-out UI· μπλοκαρισμένη → `itemsInUseTooltip`.
  Future<({bool ok, String? error})> deleteCategory(int id) {
    final repo = ref.read(categoryRepositoryProvider);
    return _delete(
      id: id,
      countInUse: repo.countItemsInUse,
      remove: repo.deleteWithContents,
      invalidateGuards: (id) {
        ref.invalidate(canDeleteCategoryProvider(id));
        ref.invalidate(inUseCountCategoryProvider(id));
      },
      okLog: 'Διαγραφή κατηγορίας',
    );
  }

  /// Δημιουργεί υποκατηγορία στην [categoryId] (exact-match dup-check).
  Future<({bool ok, String? error})> createSubCategory({
    required int categoryId,
    required String name,
  }) {
    final repo = ref.read(subCategoryRepositoryProvider);
    return _create(
      name: name,
      findClash: repo.getByNormalizedName,
      insert: (trimmed) => repo.insert(categoryId: categoryId, name: trimmed),
      dupLog: (t) => 'Απόρριψη «+» υποκατηγορίας "$t": διπλότυπο',
      okLog: (t, id) => 'Δημιουργία υποκατηγορίας: $t (#$id, cat #$categoryId)',
    );
  }

  /// Μετονομάζει υποκατηγορία (χωρίς αλλαγή κατηγορίας — εκτός scope).
  /// Recase επιτρέπεται· clash με άλλον → `nameExists`.
  Future<({bool ok, String? error})> renameSubCategory(int id, String name) {
    final repo = ref.read(subCategoryRepositoryProvider);
    return _rename(
      id: id,
      name: name,
      load: (id) async {
        final s = await repo.getById(id);
        return s == null ? null : (id: s.id, name: s.name);
      },
      findClash: (n) async {
        final s = await repo.getByNormalizedName(n);
        return s == null ? null : (id: s.id);
      },
      save: (id, trimmed) async {
        await repo.updateById(id, name: trimmed);
      },
      dupLog: (id, t) =>
          'Απόρριψη μετονομασίας υποκατηγορίας #$id σε "$t": διπλότυπο',
      okLog: (id, t) => 'Μετονομασία υποκατηγορίας #$id: $t',
    );
  }

  /// Διαγράφει υποκατηγορία με τμήματα + ορφανά είδη (cascade, §2.3 Α/Γ).
  Future<({bool ok, String? error})> deleteSubCategory(int id) {
    final repo = ref.read(subCategoryRepositoryProvider);
    return _delete(
      id: id,
      countInUse: repo.countItemsInUse,
      remove: repo.deleteWithContents,
      invalidateGuards: (id) {
        ref.invalidate(canDeleteSubCategoryProvider(id));
        ref.invalidate(inUseCountSubCategoryProvider(id));
      },
      okLog: 'Διαγραφή υποκατηγορίας',
    );
  }

  /// Δημιουργεί τμήμα στην [subCategoryId] (27-09-2026 · exact-match).
  Future<({bool ok, String? error})> createItemGroup({
    required int subCategoryId,
    required String name,
  }) {
    final repo = ref.read(itemGroupRepositoryProvider);
    return _create(
      name: name,
      findClash: repo.getByNormalizedName,
      insert: (trimmed) =>
          repo.insert(subCategoryId: subCategoryId, name: trimmed),
      dupLog: (t) => 'Απόρριψη «+» τμήματος "$t": διπλότυπο',
      okLog: (t, id) => 'Δημιουργία τμήματος: $t (#$id, sub #$subCategoryId)',
    );
  }

  /// Μετονομάζει τμήμα (χωρίς αλλαγή υποκατηγορίας). Recase επιτρέπεται.
  Future<({bool ok, String? error})> renameItemGroup(int id, String name) {
    final repo = ref.read(itemGroupRepositoryProvider);
    return _rename(
      id: id,
      name: name,
      load: (id) async {
        final g = await repo.getById(id);
        return g == null ? null : (id: g.id, name: g.name);
      },
      findClash: (n) async {
        final g = await repo.getByNormalizedName(n);
        return g == null ? null : (id: g.id);
      },
      save: (id, trimmed) async {
        await repo.updateById(id, name: trimmed);
      },
      dupLog: (id, t) =>
          'Απόρριψη μετονομασίας τμήματος #$id σε "$t": διπλότυπο',
      okLog: (id, t) => 'Μετονομασία τμήματος #$id: $t',
    );
  }

  /// Διαγράφει τμήμα με τα ορφανά είδη του (cascade, §2.3 Α/Γ).
  Future<({bool ok, String? error})> deleteItemGroup(int id) {
    final repo = ref.read(itemGroupRepositoryProvider);
    return _delete(
      id: id,
      countInUse: repo.countItemsInUse,
      remove: repo.deleteWithContents,
      invalidateGuards: (id) {
        ref.invalidate(canDeleteItemGroupProvider(id));
        ref.invalidate(inUseCountItemGroupProvider(id));
      },
      okLog: 'Διαγραφή τμήματος',
    );
  }

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
