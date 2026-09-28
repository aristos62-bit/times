/// Controller εξαγωγής καρτέλας (§2.3 DESIGN · 28-09-2026 — 1η ανάλυση).
///
/// Plain `Notifier<SettingsState>` (όχι AsyncNotifier): σύγχρονο state
/// (μόνο `isWorking` flag, pattern `BackupRestoreController` — οι γραμμές
/// έρχονται από το widget που κάνει watch, όχι από εδώ). NON-autoDispose
/// (§2.2:221, IndexedStack).
///
/// Contract `(ok,error)` για `runControllerOp`: ακύρωση picker →
/// `(ok:false, error:null)` (no-op)· `AppException` ανέγγιχτο (feedback στο
/// widget). Τα dialogs δεν ζουν εδώ (pattern editors §2.3).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/chart_totals.dart';
import '../../../data/providers/settings_providers.dart';
import '../../../domain/services/statistics_export.dart';
import '../state/settings_state.dart';

/// SPoT provider εξαγωγής καρτέλας — μη autoDispose (§2.2:221).
final statisticsControllerProvider =
    NotifierProvider<StatisticsController, SettingsState>(
  StatisticsController.new,
);

/// Controller εξαγωγής καρτέλας είδους (section «Στατιστικά» §2.3).
class StatisticsController extends Notifier<SettingsState> {
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

  /// Εξάγει [rows] σε XLSX: bytes → save dialog. Ακύρωση → no-op·
  /// αποτυχία → `StatsExportException` (feedback στο widget).
  Future<({bool ok, String? error})> exportExcel(
    List<ItemLedgerRow> rows,
  ) =>
      _guarded(() async {
        final bytes = StatisticsExportService.buildExcelBytes(rows);
        return _save(
          StatisticsExportService.buildStatsFileName(
            DateTime.now(),
            StatsExportFormat.excel,
          ),
          bytes,
        );
      });

  /// Εξάγει [model] σε PDF: fonts → bytes → save dialog. Ακύρωση → no-op·
  /// αποτυχία (fonts/bytes/dialog) → `StatsExportException`.
  Future<({bool ok, String? error})> exportPdf(StatsPdfModel model) =>
      _guarded(() async {
        final (regular, bold) =
            await StatisticsExportService.loadPdfFonts();
        final bytes = await StatisticsExportService.buildPdfBytes(
          title: model.title,
          headers: model.headers,
          body: model.body,
          totalsLine: model.totalsLine,
          fontBytes: regular,
          boldFontBytes: bold,
        );
        return _save(
          StatisticsExportService.buildStatsFileName(
            DateTime.now(),
            StatsExportFormat.pdf,
          ),
          bytes,
        );
      });

  /// Save dialog + contract (pattern export backup Βήματος 5).
  Future<({bool ok, String? error})> _save(
    String fileName,
    List<int> bytes,
  ) async {
    bool saved;
    try {
      saved = await ref.read(backupFilePickerProvider).saveBytes(
            fileName: fileName,
            bytes: bytes,
          );
    } on Exception catch (e, s) {
      AppLogger.error(
        LogTag.stats,
        'Αποτυχία διαλόγου αποθήκευσης',
        e,
        s,
      );
      throw const StatsExportException();
    }
    if (!saved) {
      AppLogger.info(LogTag.stats, 'Εξαγωγή ακυρώθηκε από τον χρήστη');
      return (ok: false, error: null);
    }
    AppLogger.info(LogTag.stats, 'Εξαγωγή ολοκληρώθηκε: $fileName');
    return (ok: true, error: null);
  }
}
