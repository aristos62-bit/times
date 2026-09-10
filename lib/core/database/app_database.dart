import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../debug/app_logger.dart';
import '../debug/debug_config.dart';
import 'database_file.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

/// SPO: Main Drift database class
///
/// **storeDateTimeAsText: true** — ΑΠΑΡΑΙΤΗΤΟ για σωστές συγκρίσεις ημερομηνιών
/// σε SQLite. Χωρίς αυτό, DateTime αποθηκεύεται ως INTEGER (unix) και
/// string comparisons (`r.receipt_date >= '2026-01-01'`) αποτυγχάνουν σιωπηλά.
@DriftDatabase(tables: [
  Categories,
  Suppliers,
  Items,
  Receipts,
  ReceiptItems,
  Payments,
  PriceHistory,
  Budgets,
  Tags,
  ReceiptTags,
  UserSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Test constructor: in-memory database
  AppDatabase.test() : super(NativeDatabase.memory());

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  int get schemaVersion => AppConstants.dbVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          AppLogger.db('Creating database schema (v$schemaVersion)...');
          await m.createAll();
          await _seedAllVersions();
          AppLogger.db('Schema created + seed data inserted.');
        },
        onUpgrade: (m, from, to) async {
          AppLogger.db('Upgrading schema from v$from to v$to...');
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          AppLogger.db('Database opened. FK constraints enabled.');
          // Data migrations αφορούν ΜΟΝΟ υπάρχουσα βάση (upgrade) — σε fresh
          // install το onCreate έκανε ήδη πλήρες seed ατομικά (1 batch).
          if (!details.wasCreated) {
            await _applyDataMigrations();
          }
        },
      );

  /// Seed versioned — κάθε έκδοση seed έχει ξεχωριστή έξοδο
  static const int currentSeedVersion = 1;

  Future<void> _seedAllVersions() async {
    await _runSeedV1();
  }

  Future<void> _runSeedV1() async {
    AppLogger.db('Running seed V1 (default categories + settings)...');
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(
            name: 'Τρόφιμα',
            icon: const Value('🍽️'),
            color: const Value('#2196F3'),
            sortOrder: const Value(1),
            createdAt: now,
            updatedAt: now),
        CategoriesCompanion.insert(
            name: 'Οικιακά',
            icon: const Value('🏠'),
            color: const Value('#4CAF50'),
            sortOrder: const Value(2),
            createdAt: now,
            updatedAt: now),
        CategoriesCompanion.insert(
            name: 'Μεταφορικά',
            icon: const Value('🚗'),
            color: const Value('#FF9800'),
            sortOrder: const Value(3),
            createdAt: now,
            updatedAt: now),
        CategoriesCompanion.insert(
            name: 'Υγεία',
            icon: const Value('💊'),
            color: const Value('#E91E63'),
            sortOrder: const Value(4),
            createdAt: now,
            updatedAt: now),
        CategoriesCompanion.insert(
            name: 'Ένδυση',
            icon: const Value('👕'),
            color: const Value('#9C27B0'),
            sortOrder: const Value(5),
            createdAt: now,
            updatedAt: now),
        CategoriesCompanion.insert(
            name: 'Ψυχαγωγία',
            icon: const Value('🎮'),
            color: const Value('#00BCD4'),
            sortOrder: const Value(6),
            createdAt: now,
            updatedAt: now),
        CategoriesCompanion.insert(
            name: 'Εκπαίδευση',
            icon: const Value('📚'),
            color: const Value('#795548'),
            sortOrder: const Value(7),
            createdAt: now,
            updatedAt: now),
        CategoriesCompanion.insert(
            name: 'Λοιπά',
            icon: const Value('📦'),
            color: const Value('#607D8B'),
            sortOrder: const Value(8),
            createdAt: now,
            updatedAt: now),
      ]);
      batch.insertAll(
        userSettings,
        [
          UserSettingsCompanion.insert(
              key: 'theme_mode',
              value: const Value('0'),
              type: const Value('int'),
              updatedAt: now),
          UserSettingsCompanion.insert(
              key: 'currency',
              value: const Value('€'),
              type: const Value('string'),
              updatedAt: now),
          UserSettingsCompanion.insert(
              key: 'default_vat_rate',
              value: const Value('24.0'),
              type: const Value('double'),
              updatedAt: now),
          UserSettingsCompanion.insert(
              key: 'receipt_number_counter',
              value: const Value('1'),
              type: const Value('int'),
              updatedAt: now),
          // version-stamp ΜΕΣΑ στο ίδιο batch → seed πλήρως ατομικό (ένα
          // implicit transaction). Σε re-run, insertOrReplace + unique(key)
          // στον user_settings κάνουν το stamp idempotent.
          UserSettingsCompanion.insert(
              key: 'seed_version',
              value: const Value('1'),
              type: const Value('int'),
              updatedAt: now),
        ],
        mode: InsertMode.insertOrReplace,
      );
    });
    AppLogger.db('Seed V1 complete. 8 categories + 5 settings inserted.');
  }

  /// Data migrations — τρέχει σε ΥΠΑΡΧΟΥΣΑ βάση μετά από upgrade
  Future<void> _applyDataMigrations() async {
    final version = await _getSeedVersion();
    AppLogger.db('Current seed version: $version');
    if (version < currentSeedVersion) {
      await _runSeedV1();
    }
  }

  Future<int> _getSeedVersion() async {
    final row = await (select(userSettings)
          ..where((s) => s.key.equals('seed_version')))
        .getSingleOrNull();
    return row != null ? int.tryParse(row.value ?? '') ?? 0 : 0;
  }

  @override
  Future<void> close() async {
    AppLogger.db('Closing database connection.');
    await super.close();
  }
}

/// SPO: Database connection factory
///
/// **Timezone:** ΕΠΙΒΑΛΛΕΤΑΙ από το `UtcDateTimeConverter` σε κάθε
/// DateTime column — αποθήκευση UTC, εμφάνιση local.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final sw = Stopwatch()..start();
    try {
      final file = await resolveDatabaseFile();

      AppLogger.db('Opening database: ${file.path}');
      final connection = NativeDatabase.createInBackground(file);

      sw.stop();
      if (sw.elapsed > DebugConfig.slowQueryThreshold) {
        AppLogger.performance('Database open: ${sw.elapsed.inMilliseconds}ms');
      }
      return connection;
    } catch (e, stackTrace) {
      sw.stop();
      AppLogger.error('Database open failed: $e', stackTrace);
      rethrow;
    }
  });
}

/// SPO: Database singleton
final database = AppDatabase();
