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
import '../../../data/providers/database_providers.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../domain/services/backup_service.dart';
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

  /// Επαναφέρει το [candidatePath] (ΚΑΛΕΙΤΑΙ ΜΟΝΟ μετά από confirm στο widget).
  /// Ξανατρέχει validation (defense — το αρχείο μπορεί να άλλαξε) →
  /// auto-backup (αποτυχία = abort ΠΡΙΝ το close) → `closeSafely()` →
  /// replace → restart providers + reset φορμών (stale ids → FK σφάλμα
  /// αλλιώς). Αποτυχία → mapped `AppException` (feedback στο widget).
  Future<({bool ok, String? error})> restoreBackup(String candidatePath) =>
      _guarded(() async {
        final service = ref.read(backupServiceProvider);
        await service.validateBackupFile(candidatePath);
        final autoPath = await service.autoBackupCurrent();
        AppLogger.info(LogTag.backup, 'Auto-backup πριν restore: $autoPath');
        await ref.read(appDatabaseProvider).closeSafely();
        await service.replaceDatabaseFile(candidatePath);
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
