/// Domain service εξαγωγής/επαναφοράς αντιγράφου βάσης (§2.3 DESIGN /
/// Φάση 4 Βήμα 5).
///
/// Καθαρό IO layer (όχι DAO/repository — δεν είναι πίνακας, είναι αρχείο):
/// snapshot μέσω `VACUUM INTO` (WAL-safe, εκτός transaction — SQLite
/// restriction), validation υποψήφιου αρχείου (magic + 7 πίνακες §3, καμία
/// αλλαγή), αντικατάσταση αρχείου. Τα σφάλματα βγαίνουν ως `AppException`
/// (pattern `ReceiptRepositoryImpl._guard`): κάθε `Exception` → mapped
/// (log tag `backup` εδώ), απρόβλεπτα `Error` ανεβαίνουν raw.
/// Προσαρμογή 24-09 (evidence pub cache): το `file_picker` 12 `saveFile`
/// θέλει bytes (όχι path) — το export κάνει snapshot σε temp + ο controller
/// δίνει τα bytes στο picker· το service δεν αγγίζει το picker (testable).
library;

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/logging/app_logger.dart';
import '../../data/local/app_database.dart';

/// SPoT service αντιγράφων — κρατά την ανοιχτή βάση (injected, όχι singleton).
final class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Αναμενόμενοι πίνακες §3 (drift snake_case — τα `receipts`/`suppliers` /
  /// `receipt_lines` επιβεβαιωμένα από το SQL του `ReceiptDao`, οι υπόλοιποι
  /// από την ίδια γεννήτρια ονομάτων).
  static const Set<String> expectedTables = {
    'categories',
    'sub_categories',
    'units',
    'items',
    'suppliers',
    'receipts',
    'receipt_lines',
  };

  /// Χτίζει filename από το SPoT pattern + timestamp (manual pad,
  /// non-localized — σκόπιμα όχι `DateFormat`, το όνομα αρχείου δεν
  /// εξαρτάται από locale).
  static String buildBackupFileName(DateTime now) {
    String p2(int v) => v.toString().padLeft(2, '0');
    final name = AppConstants.backupFileNamePattern
        .replaceAll('yyyy', now.year.toString().padLeft(4, '0'))
        .replaceAll('MM', p2(now.month))
        .replaceAll('dd', p2(now.day))
        .replaceAll('HH', p2(now.hour))
        .replaceAll('mm', p2(now.minute))
        .replaceAll('ss', p2(now.second));
    return '$name.sqlite';
  }

  /// Το αρχείο της τρέχουσας βάσης (`<docs>/times.sqlite` — evidence
  /// `drift_flutter` native.dart: `File(docs, '$name.sqlite')`).
  Future<File> currentDbFile() async {
    final docs = await getApplicationDocumentsDirectory();
    return File('${docs.path}${Platform.pathSeparator}times.sqlite');
  }

  /// Temp path για το snapshot εξαγωγής (`<docs>/export_tmp_<ts>.sqlite` —
  /// ο controller το σβήνει πάντα (`finally`), επιτυχία ή ακύρωση).
  Future<String> exportTempPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}${Platform.pathSeparator}'
        'export_tmp_${DateTime.now().millisecondsSinceEpoch}.sqlite';
  }

  /// WAL-safe snapshot της ανοιχτής βάσης στο [targetPath] (εκτός
  /// transaction). Αποτυχία → `BackupCreationException` (`backupFailed`).
  Future<void> exportSnapshot(String targetPath) async {
    final escaped = targetPath.replaceAll("'", "''");
    try {
      await _db.customStatement("VACUUM INTO '$escaped'");
      AppLogger.info(LogTag.backup, 'Snapshot εξαγωγής: $targetPath');
    } on Exception catch (e, s) {
      AppLogger.error(LogTag.backup, 'Αποτυχία snapshot εξαγωγής', e, s);
      throw const BackupCreationException();
    }
  }

  /// Διαβάζει ΟΛΑ τα bytes αρχείου (για το picker `saveFile`). Αποτυχία →
  /// `BackupCreationException`.
  Future<List<int>> readBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } on Exception catch (e, s) {
      AppLogger.error(LogTag.backup, 'Αποτυχία ανάγνωσης snapshot', e, s);
      throw const BackupCreationException();
    }
  }

  /// Σβήνει temp αρχείο (best effort — αποτυχία = info log, ποτέ throw).
  Future<void> deleteTemp(String path) async {
    try {
      await File(path).delete();
    } on Exception catch (e) {
      AppLogger.info(LogTag.backup, 'Temp δεν σβήστηκε: $path | $e');
    }
  }

  /// Υποχρεωτικό auto-backup τρέχουσας βάσης πριν το restore (safety net
  /// §1.9/απόφαση Δ): snapshot στο `<docs>/auto_<ts>.sqlite`. Επιστρέφει το
  /// path (για logs). Αποτυχία → `BackupCreationException` (abort πριν το
  /// close — η τρέχουσα βάση μένει άθικτη).
  Future<String> autoBackupCurrent() async {
    final docs = await getApplicationDocumentsDirectory();
    final name = 'auto_${buildBackupFileName(DateTime.now())}';
    final path = '${docs.path}${Platform.pathSeparator}$name';
    await exportSnapshot(path);
    return path;
  }

  /// Validation υποψήφιου αρχείου ΠΡΙΝ από οτιδήποτε (§2.3: magic + πίνακες,
  /// καμία αλλαγή): 1) υπάρχει 2) SQLite magic 3) πίνακες με read-only probe
  /// (ποτέ drift open — θα έγραφε schema σε άδειο αρχείο). Αποτυχία →
  /// `InvalidBackupFileException` (`invalidBackupFile`).
  Future<void> validateBackupFile(String candidatePath) async {
    final file = File(candidatePath);
    // ΣΥΓΧΡΟΝΟ IO επίτηδες (existsSync/openSync/readSync/closeSync): το async
    // File IO κολλάει στο widget-test FakeAsync zone (empirical 24-09:
    // exists=true/open=false), ενώ το sync περνά παντού (zone-proof)·
    // κόστος μικροδευτερόλεπτα (16 bytes).
    try {
      if (!file.existsSync()) {
        throw const InvalidBackupFileException();
      }
      final raf = file.openSync();
      try {
        final header = raf.readSync(16);
        const magic = 'SQLite format 3\x00';
        if (String.fromCharCodes(header) != magic) {
          AppLogger.info(LogTag.backup, 'Άκυρο magic αντιγράφου');
          throw const InvalidBackupFileException();
        }
      } finally {
        raf.closeSync();
      }
    } on InvalidBackupFileException {
      rethrow;
    } on Exception catch (e, s) {
      AppLogger.error(LogTag.backup, 'Αποτυχία validation αντιγράφου', e, s);
      throw const InvalidBackupFileException();
    }

    // Πίνακες με read-only probe στο ΙΔΙΟ isolate (package:sqlite3):
    // ούτε drift background isolate (hang σε widget tests — εύρημα Ε2
    // Βήματος 4) ούτε mutation (readOnly) ούτε αντίγραφο αρχείου.
    try {
      final probe = sqlite3.open(candidatePath, mode: OpenMode.readOnly);
      try {
        final names = {
          for (final row in probe.select(
            "SELECT name FROM sqlite_master WHERE type = 'table'",
          ))
            row['name'] as String,
        };
        if (!names.containsAll(expectedTables)) {
          AppLogger.info(LogTag.backup, 'Λείπουν πίνακες: $names');
          throw const InvalidBackupFileException();
        }
      } finally {
        probe.close();
      }
      AppLogger.info(LogTag.backup, 'Validation αντιγράφου ΟΚ');
    } on InvalidBackupFileException {
      rethrow;
    } on Exception catch (e, s) {
      AppLogger.error(LogTag.backup, 'Αποτυχία ελέγχου πινάκων', e, s);
      throw const InvalidBackupFileException();
    }
  }

  /// Αντικαθιστά το αρχείο βάσης με το [sourcePath].
  /// ΠΡΟΫΠΟΘΕΣΗ (controller): `closeSafely()` πριν (αλλιώς file-lock,
  /// ιδίως Windows). Αποτυχία → `RestoreBackupException` (`restoreFailed`).
  /// Stale sidecars (`-wal`/`-shm`/`-journal`) σβήνονται ΜΕΤΑ το copy (όχι
  /// πριν — αλλιώς διπλό-σφάλμα close+copy θα άφηνε την παλιά βάση χωρίς
  /// το journal της)· best-effort via `deleteTemp`, ποτέ throw.
  Future<void> replaceDatabaseFile(String sourcePath) async {
    try {
      final target = await currentDbFile();
      await File(sourcePath).copy(target.path);
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        await deleteTemp('${target.path}$suffix');
      }
      AppLogger.info(LogTag.backup, 'Αντικατάσταση βάσης από: $sourcePath');
    } on Exception catch (e, s) {
      AppLogger.error(LogTag.backup, 'Αποτυχία αντικατάστασης βάσης', e, s);
      throw const RestoreBackupException();
    }
  }
}
