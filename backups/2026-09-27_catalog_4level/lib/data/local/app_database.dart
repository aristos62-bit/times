/// SPoT σύνδεσης με τη βάση SQLite μέσω Drift — Φάση 1, Βήμα 1.
///
/// Οι πίνακες ορίζονται στο `tables.dart` (§3 DESIGN). Στο `onCreate`
/// δημιουργείται όλο το σχήμα, εκτελείται το seed δεδομένων (Βήμα 3, §4.1),
/// το `onUpgrade` v1→v2 καθαρίζει legacy μονάδες (data-only, βλ.
/// `migration_v1_to_v2.dart`) · v2→v3 προσθέτει `discountCents` (έκπτωση
/// γραμμής, §2.2) και στο `beforeOpen` ενεργοποιείται το
/// `PRAGMA foreign_keys = ON` (τρέχει μετά από κάθε migration/reopen).
/// Logging μέσω `AppLogger` με tag `DB` (§1.7).
library;

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/logging/app_logger.dart';
import 'migration_v1_to_v2.dart';
import 'seed/seed_runner.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Η βάση δεδομένων της εφαρμογής.
///
/// Μοναδικό σημείο (SPoT) για το schema SQLite. Οι λειτουργίες των μερών
/// της εφαρμογής (item catalog, receipts κ.λπ.) θα χρησιμοποιούν μόνο
/// αυτό το αντικείμενο για ερωτήματα. Το προαιρετικό [executor] επιτρέπει
/// in-memory βάση στα tests· στην παραγωγή ανοίγεται το αρχείο [dbFileName].
@DriftDatabase(tables: [
  Categories,
  SubCategories,
  Units,
  Items,
  Suppliers,
  Receipts,
  ReceiptLines,
])
class AppDatabase extends _$AppDatabase {
  /// Κατασκευή με δυνατότητα ορισμού custom [executor] για testing.
  /// Αν δεν δοθεί, χρησιμοποιείται το default drift executor.
  /// Αν [skipSeed] είναι `true`, δεν εκτελείται seed — απαραίτητο στα tests
  /// ώστε να μην πολλαπλασιάζονται τα είδη σε κάθε test run.
  AppDatabase({QueryExecutor? executor, this.skipSeed = false})
      : super(executor ?? _openConnection());

  /// Όνομα του αρχείου βάσης στον χώρο της εφαρμογής.
  static const dbFileName = 'times';

  /// Αν `true`, δεν εκτελείται seed στο `onCreate` (χρήσιμο στα tests).
  final bool skipSeed;

  /// Flag idempotent κλεισίματος (Φάση 4 Βήμα 5, απόφαση Β): το drift
  /// `close()` δεν είναι idempotent (double-close = σφάλμα) — το
  /// `closeSafely()` το καλεί μία φορά, οι επόμενες είναι no-op.
  bool _closed = false;

  static DatabaseConnection _openConnection() =>
      driftDatabase(name: dbFileName);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          AppLogger.info(LogTag.db, 'Δημιουργία βάσης (times)');
          if (!skipSeed) {
            await runSeed(this);
          }
        },
        // v2 → v3 (25-09-2026): στήλη έκπτωσης γραμμής, schema-πρώτα
        // (οι παλιές γραμμές παίρνουν 0 — σύνολα άθικτα)· v1 → v2 data
        // migration μένει για παλιές εγκαταστάσεις/backups.
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.addColumn(receiptLines, receiptLines.discountCents);
          }
          if (from == 1) {
            await migrateV1ToV2(this);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          AppLogger.info(LogTag.db, 'PRAGMA foreign_keys = ON');
        },
      );

  /// Idempotent κλείσιμο (Φάση 4 Βήμα 5, απόφαση Β · §2.3 restore).
  ///
  /// 1η κλήση → `close()` + info log· επόμενες → no-op. Αποτυχία → error
  /// log (tag DB) χωρίς rethrow — ο καλών (restore/onDispose) συνεχίζει
  /// (το replace θα αποτύχει με mapped exception αν το αρχείο κλειδώθηκε).
  Future<void> closeSafely() async {
    if (_closed) return;
    _closed = true;
    // Probe 1 (διάγνωση hang restore): απαντά ο executor; Με timeout και
    // catch-all — ποτέ throw, μόνο log (δεν αλλάζει τη ροή κλεισίματος).
    try {
      await customSelect('SELECT 1').get().timeout(
            Duration(seconds: AppConstants.restoreProbeTimeoutSeconds),
          );
      AppLogger.info(LogTag.db, 'closeSafely: probe SELECT 1 OK');
    } on TimeoutException {
      AppLogger.info(LogTag.db, 'closeSafely: probe SELECT 1 TIMEOUT');
    } catch (e) {
      AppLogger.info(LogTag.db, 'closeSafely: probe SELECT 1 error: $e');
    }
    try {
      AppLogger.info(LogTag.db, 'closeSafely: κλείσιμο βάσης…');
      await close().timeout(
        Duration(seconds: AppConstants.restoreCloseTimeoutSeconds),
      );
      AppLogger.info(LogTag.db, 'Κλείσιμο βάσης');
    } on TimeoutException {
      // Αποδεδειγμένο hang (συσκευή 27-09-2026): ο executor απαντά (probe
      // OK) αλλά το teardown δεν ολοκληρώνεται — συνέχεια στο replace αντί
      // για παγωμένη εφαρμογή (αποτυχία → mapped exception + snackbar).
      AppLogger.info(LogTag.db, 'closeSafely: TIMEOUT — συνέχεια χωρίς close');
    } catch (e, s) {
      AppLogger.error(LogTag.db, 'Αποτυχία κλεισίματος βάσης', e, s);
    }
  }
}