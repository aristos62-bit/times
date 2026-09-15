/// SPoT σύνδεσης με τη βάση SQLite μέσω Drift — Φάση 1, Βήμα 1.
///
/// Οι πίνακες ορίζονται στο `tables.dart` (§3 DESIGN). Στο `onCreate`
/// δημιουργείται όλο το σχήμα και στο `beforeOpen` ενεργοποιείται το
/// `PRAGMA foreign_keys = ON` (τρέχει μετά από κάθε migration/reopen).
/// Logging μέσω `AppLogger` με tag `DB` (§1.7).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/logging/app_logger.dart';
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
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Όνομα του αρχείου βάσης στον χώρο της εφαρμογής.
  static const dbFileName = 'times';

  static DatabaseConnection _openConnection() =>
      driftDatabase(name: dbFileName);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          AppLogger.info(LogTag.db, 'Δημιουργία βάσης (times)');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          AppLogger.info(LogTag.db, 'PRAGMA foreign_keys = ON');
        },
      );
}