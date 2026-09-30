/// Controller εξαγωγής/επαναφοράς αντιγράφου (§2.3 DESIGN / Φάση 4 Βήμα 5).
///
/// Plain `Notifier<SettingsState>` (όχι AsyncNotifier): το state είναι
/// σύγχρονο (μόνο `isWorking` flag)· δεν υπάρχει live stream (όπως το Theme
/// section — όχι `AsyncValue.when`). Pattern `CategoryManagementController`
/// (σύγχρονο state + async actions με flag + `_guarded`). NON-autoDispose
/// (§2.2:221, IndexedStack).
///
/// Σειρά restore (κλειδωμένη Δ): validate → (confirm στο widget) →
/// auto-backup → `closeSafely()` → replace → `invalidate(appDatabaseProvider)`
/// + reset φορμών. Το confirm dialog ζει στο widget (οι controllers δεν
/// δείχνουν dialogs — pattern editors §2.3). Validation/dup → record
/// `(ok:false, error:)`· `AppException` ανεβαίνει ανέγγιχτο (feedback στο
/// widget μέσω `runControllerOp`, που πιάνει `AppException`).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/category_tree_node.dart';
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../data/providers/stream_providers.dart';
import '../../../domain/services/backup_service.dart';
import '../../../domain/services/catalog_export.dart';
import '../../price_entry/controllers/item_search_controller.dart';
import '../../price_entry/controllers/receipt_form_controller.dart';
import '../state/settings_state.dart';

/// SPoT provider διαχείρισης αντιγράφων — μη autoDispose (§2.2:221).
final backupRestoreControllerProvider =
    NotifierProvider<BackupRestoreController, SettingsState>(
      BackupRestoreController.new,
    );

/// Controller backup/restore (section «Αντίγραφα» §2.3 · Βήμα 5).
class BackupRestoreController extends Notifier<SettingsState> {
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

  /// Probe 2 (διάγνωση hang restore): ποια DB stream providers ζουν πριν
  /// το close — `ref.exists` (sync, χωρίς side effects), μόνο log.
  void _logLiveStreams() {
    final live = <String, bool>{
      'category': ref.exists(categoryStreamProvider),
      'subCategories': ref.exists(subCategoriesStreamProvider),
      'units': ref.exists(unitsStreamProvider),
      'items': ref.exists(itemsStreamProvider),
      'suppliers': ref.exists(suppliersStreamProvider),
      'receipts': ref.exists(receiptsStreamProvider),
      'recentReceipts': ref.exists(recentReceiptsStreamProvider),
      'receiptsByDay': ref.exists(receiptsByDayStreamProvider),
    };
    AppLogger.info(LogTag.backup, 'Restore: live streams πριν close: $live');
  }

  /// Εξάγει αντίγραφο: snapshot temp → bytes → save dialog → cleanup.
  /// Ακύρωση picker → `(ok:false, error:null)` (no-op, χωρίς snackbar).
  /// Αποτυχία → `BackupCreationException` (feedback στο widget).
  Future<({bool ok, String? error})> exportBackup() => _guarded(() async {
        final service = ref.read(backupServiceProvider);
        final picker = ref.read(backupFilePickerProvider);
        final fileName = BackupService.buildBackupFileName(DateTime.now());
        final tmp = await service.exportTempPath();
        try {
          await service.exportSnapshot(tmp);
          final bytes = await service.readBytes(tmp);
          bool saved;
          try {
            saved = await picker.saveBytes(
              fileName: fileName,
              bytes: bytes,
            );
          } on Exception catch (e, s) {
            AppLogger.error(
              LogTag.backup,
              'Αποτυχία διαλόγου αποθήκευσης',
              e,
              s,
            );
            throw const BackupCreationException();
          }
          if (!saved) {
            AppLogger.info(LogTag.backup, 'Εξαγωγή ακυρώθηκε από τον χρήστη');
            return (ok: false, error: null);
          }
          AppLogger.info(LogTag.backup, 'Εξαγωγή ολοκληρώθηκε: $fileName');
          return (ok: true, error: null);
        } finally {
          await service.deleteTemp(tmp);
        }
      });

  /// Ελέγχει υποψήφιο αρχείο (για το widget ΠΡΙΝ το confirm — κλειδωμένη
  /// σειρά Δ: confirm μόνο σε έγκυρο). Άκυρο → `(ok:false, error:)`·
  /// απρόβλεπτο → rethrow (feedback στο widget).
  Future<({bool ok, String? error})> validateCandidate(String path) =>
      _guarded(() async {
        try {
          await ref.read(backupServiceProvider).validateBackupFile(path);
          return (ok: true, error: null);
        } on InvalidBackupFileException catch (e) {
          return (ok: false, error: e.userMessage);
        }
      });

  /// Εξάγει ολόκληρο τον κατάλογο (δέντρο + είδη + μονάδες) σε XLSX
  /// (§2.3 · 30-09-2026). Διαβάζει τα repos κατευθείαν με one-shot
  /// `.first` (precedent `itemSearchController` + `appDatabaseProvider`
  /// στον ίδιο controller — ΟΧΙ `.future` providers: εύρημα Φάσης 2
  /// Βήματος 3, hang — και ΟΧΙ `AsyncValue.when`: η section μένει
  /// data-less σκόπιμα). Σύνθεση δέντρου μέσω pure `buildCategoryTreeNodes`
  /// (SPoT §1.1, ίδια με τον `categoryTreeStreamProvider`).
  /// Σφάλμα stream → `DataLoadException` (υπάρχων δρόμος `runControllerOp`).
  /// Ακύρωση picker → `(ok:false, error:null)`· αποτυχία builder/dialog →
  /// `CatalogExportException` (feedback στο widget).
  Future<({bool ok, String? error})> exportCatalog() => _guarded(() async {
        final cats =
            await ref.read(categoryRepositoryProvider).watchAll().first;
        final subs =
            await ref.read(subCategoryRepositoryProvider).watchAll().first;
        final groups =
            await ref.read(itemGroupRepositoryProvider).watchAll().first;
        final items = await ref.read(itemRepositoryProvider).watchAll().first;
        final units = await ref.read(unitRepositoryProvider).watchAll().first;
        final bytes = CatalogExportService.buildCatalogExcelBytes(
          tree: buildCategoryTreeNodes(cats, subs, groups),
          items: items,
          units: units,
        );
        final fileName = CatalogExportService.buildCatalogFileName(
          DateTime.now(),
        );
        final picker = ref.read(backupFilePickerProvider);
        bool saved;
        try {
          saved = await picker.saveBytes(fileName: fileName, bytes: bytes);
        } on Exception catch (e, s) {
          AppLogger.error(
            LogTag.backup,
            'Αποτυχία διαλόγου αποθήκευσης καταλόγου',
            e,
            s,
          );
          throw const CatalogExportException();
        }
        if (!saved) {
          AppLogger.info(
            LogTag.backup,
            'Εξαγωγή καταλόγου ακυρώθηκε από τον χρήστη',
          );
          return (ok: false, error: null);
        }
        AppLogger.info(LogTag.backup, 'Εξαγωγή καταλόγου: $fileName');
        return (ok: true, error: null);
      });

  /// Επαναφέρει το [candidatePath] (ΚΑΛΕΙΤΑΙ ΜΟΝΟ μετά από confirm στο widget).
  /// Ξανατρέχει validation (defense — το αρχείο μπορεί να άλλαξε) →
  /// auto-backup (αποτυχία = abort ΠΡΙΝ το close) → `closeSafely()` →
  /// replace → restart providers + reset φορμών (stale ids → FK σφάλμα
  /// αλλιώς). Αποτυχία → mapped `AppException` (feedback στο widget).
  Future<({bool ok, String? error})> restoreBackup(String candidatePath) =>
      _guarded(() async {
        final service = ref.read(backupServiceProvider);
        AppLogger.info(LogTag.backup, 'Restore: έναρξη — validation');
        await service.validateBackupFile(candidatePath);
        AppLogger.info(LogTag.backup, 'Restore: validation OK — auto-backup');
        final autoPath = await service.autoBackupCurrent();
        AppLogger.info(LogTag.backup, 'Auto-backup πριν restore: $autoPath');
        AppLogger.info(LogTag.backup, 'Restore: auto-backup OK — closeSafely');
        _logLiveStreams();
        await ref.read(appDatabaseProvider).closeSafely();
        AppLogger.info(LogTag.backup, 'Restore: close OK — replace');
        await service.replaceDatabaseFile(candidatePath);
        AppLogger.info(
          LogTag.backup,
          'Restore: replace OK — invalidate+reset',
        );
        ref.invalidate(appDatabaseProvider);
        // Stale in-memory state (ids παλιάς βάσης): πλήρες reset — αλλιώς το
        // επόμενο save θα έσκαγε σε FK (pattern `deleteSupplier` §2.3).
        // Το `onQueryChanged('')` καθαρίζει ΚΑΙ pending search (όχι μόνο
        // `clearSelection` — η βάση άλλαξε ταυτότητα).
        ref.read(receiptFormControllerProvider.notifier).resetForm();
        ref.read(itemSearchControllerProvider.notifier).onQueryChanged('');
        AppLogger.info(LogTag.backup, 'Επαναφορά ολοκληρώθηκε');
        return (ok: true, error: null);
      });
}
