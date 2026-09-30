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

  /// Αναμενόμενοι πίνακες §3 (drift snake_case, 27-09-2026: 8 με
  /// `item_groups`).
  static const Set<String> expectedTables = {
    'categories',
    'sub_categories',
    'item_groups',
    'units',
    'items',
    'suppliers',
    'receipts',
    'receipt_lines',
  };

  /// Αναμενόμενες στήλες ανά πίνακα (30-09-2026 · SPoT, δίπλα στο
  /// `expectedTables`): πηγή `tables.dart` + drift snake_case. Έλεγχος
  /// superset (`expected ⊆ actual` — defense-in-depth για ίδιο version με
  /// πειραγμένο σχήμα). Αλλαγή σχήματος (bump §3) ενημερώνει ΚΑΙ εδώ.
  static const Map<String, Set<String>> expectedColumns = {
    'categories': {'id', 'name', 'normalized_name', 'created_at'},
    'sub_categories': {'id', 'category_id', 'name', 'normalized_name'},
    'item_groups': {'id', 'sub_category_id', 'name', 'normalized_name'},
    'units': {'id', 'name', 'abbreviation', 'allows_decimal'},
    'items': {
      'id',
      'item_group_id',
      'name',
      'normalized_name',
      'default_unit_id',
    },
    'suppliers': {'id', 'name', 'normalized_name', 'created_at'},
    'receipts': {'id', 'date', 'supplier_id'},
    'receipt_lines': {
      'id',
      'receipt_id',
      'item_id',
      'unit_id',
      'quantity',
      'price_cents',
      'discount_cents',
      'line_total_cents',
    },
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
    AppLogger.info(LogTag.backup, 'Restore: auto-backup — docs dir');
    final docs = await getApplicationDocumentsDirectory();
    final name = 'auto_${buildBackupFileName(DateTime.now())}';
    final path = '${docs.path}${Platform.pathSeparator}$name';
    AppLogger.info(LogTag.backup, 'Restore: auto-backup snapshot → $path');
    await exportSnapshot(path);
    return path;
  }

  /// Validation υποψήφιου αρχείου ΠΡΙΝ από οτιδήποτε (§2.3: magic +
  /// έκδοση + πίνακες + στήλες + integrity, καμία αλλαγή): 1) υπάρχει
  /// 2) SQLite magic 3) `user_version` == schema (§3 baseline v4, strict)
  /// 4) πίνακες 5) στήλες ανά πίνακα 6) `integrity_check` — με read-only
  /// probe (ποτέ drift open — θα έγραφε schema σε άδειο αρχείο).
  /// Αποτυχία → `InvalidBackupFileException` (`invalidBackupFile`).
  Future<void> validateBackupFile(String candidatePath) async {
    final file = File(candidatePath);
    AppLogger.info(LogTag.backup, 'Validation αντιγράφου: $candidatePath');
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
        // Έκδοση σχήματος (drift: `PRAGMA user_version` == schemaVersion).
        // Μόνο η τρέχουσα (strict — Q1 30-09-2026): παλιό/νεότερο αντίγραφο
        // → invalid (κανένα σιωπηλό skew στο replace).
        final versionRows = probe.select('PRAGMA user_version');
        final candidateVersion = versionRows.isNotEmpty
            ? versionRows.first['user_version'] as int
            : -1;
        if (candidateVersion != _db.schemaVersion) {
          AppLogger.info(
            LogTag.backup,
            'Ασυμβίβαστη έκδοση αντιγράφου: $candidateVersion '
            '(αναμενόμενη ${_db.schemaVersion})',
          );
          throw const InvalidBackupFileException();
        }
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
        // Στήλες ανά πίνακα (defense-in-depth: ίδιο version, πειραγμένο
        // σχήμα). Ονόματα από internal SPoT consts (όχι user input —
        // κανένα injection risk στο PRAGMA).
        for (final entry in expectedColumns.entries) {
          final actual = {
            for (final row in probe.select('PRAGMA table_info(${entry.key})'))
              (row['name'] as String).toLowerCase(),
          };
          final missing = entry.value.difference(actual);
          if (missing.isNotEmpty) {
            AppLogger.info(
              LogTag.backup,
              'Λείπουν στήλες στον ${entry.key}: $missing',
            );
            throw const InvalidBackupFileException();
          }
        }
        // Ακεραιότητα σελίδων (πλήρες — Q3 30-09-2026, όχι quick_check:
        // το σχήμα στηρίζεται σε UNIQUE indexes + FKs): κάθε γραμμή `ok`,
        // αλλιώς κατεστραμμένο (truncated copy κ.λπ.).
        final integrity = [
          for (final row in probe.select('PRAGMA integrity_check'))
            (row['integrity_check'] as String).toLowerCase(),
        ];
        if (integrity.isEmpty || integrity.any((v) => v != 'ok')) {
          AppLogger.info(LogTag.backup, 'Αποτυχία integrity_check');
          throw const InvalidBackupFileException();
        }
      } finally {
        probe.close();
      }
      AppLogger.info(LogTag.backup, 'Validation αντιγράφου ΟΚ');
    } on InvalidBackupFileException {
      rethrow;
    } on Exception catch (e, s) {
      AppLogger.error(LogTag.backup, 'Αποτυχία ελέγχου αντιγράφου', e, s);
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
      AppLogger.info(LogTag.backup, 'Restore: replace — target lookup');
      final target = await currentDbFile();
      AppLogger.info(LogTag.backup, 'Restore: replace copy → ${target.path}');
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
