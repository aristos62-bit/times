## 4. Database Layer (Drift)

### 4.1 Database Class (`core/database/app_database.dart`)

> **SPoT μονοπατιού DB**: `resolveDatabaseFile()` (`core/database/database_file.dart`) —
> το μοναδικό σημείο που υπολογίζει τη διαδρομή του αρχείου. Το χρησιμοποιούν τόσο το
> `AppDatabase` (άνοιγμα) όσο και το `BackupService` (§4.5) → καμία αλλαγή τοποθεσίας
> δεν απαιτεί αλλαγή σε 2+ σημεία. Χωρίς cyclic dependency: και τα δύο εξαρτώνται μόνο
> από το `database_file.dart`, όχι μεταξύ τους.

```dart
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
  
  // ΚΡΙΣΙΜΟ: Αποθήκευση ημερομηνιών ως ISO8601 TEXT (όχι unix timestamps).
  // Χωρίς αυτό, το Drift αποθηκεύει DateTime ως INTEGER και οι συγκρίσεις
  // τύπου `r.receipt_date >= '2026-01-01'` αποτυγχάνουν σιωπηλά
  // (στη SQLite κάθε αριθμός < κάθε κείμενο).
  // Πρέπει να οριστεί ΠΡΙΝ δημιουργηθεί οποιοδήποτε δεδομένο.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
  
  // Bump version when schema changes — SPoT: AppConstants.dbVersion
  @override
  int get schemaVersion => AppConstants.dbVersion;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedAllVersions();
    },
    onUpgrade: (m, from, to) async {
      // Future schema migrations: if (from < 2) { ... }
    },
    beforeOpen: (details) async {
      // ⚠️ ΔΙΟΡΘΩΣΗ: in drift 2.14 ΔΕΝ υπάρχει afterOpen → χρησιμοποιούμε beforeOpen.
      await customStatement('PRAGMA foreign_keys = ON');
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
    // ⚠️ ΔΙΟΡΘΩΣΗ: Χωρίς withDefault(currentDateAndTime), ο εφαρμογή
    // βάζει ρητά τα createdAt/updatedAt (local DateTime, ο converter τα
    // κάνει UTC κατά την αποθήκευση).
    final now = DateTime.now();
    await batch((batch) {
      batch.insertAll(categories, [
        CategoriesCompanion.insert(name: 'Τρόφιμα', icon: const Value('🍽️'), color: const Value('#2196F3'), sortOrder: const Value(1), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Οικιακά', icon: const Value('🏠'), color: const Value('#4CAF50'), sortOrder: const Value(2), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Μεταφορικά', icon: const Value('🚗'), color: const Value('#FF9800'), sortOrder: const Value(3), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Υγεία', icon: const Value('💊'), color: const Value('#E91E63'), sortOrder: const Value(4), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Ένδυση', icon: const Value('👕'), color: const Value('#9C27B0'), sortOrder: const Value(5), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Ψυχαγωγία', icon: const Value('🎮'), color: const Value('#00BCD4'), sortOrder: const Value(6), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Εκπαίδευση', icon: const Value('📚'), color: const Value('#795548'), sortOrder: const Value(7), createdAt: now, updatedAt: now),
        CategoriesCompanion.insert(name: 'Λοιπά', icon: const Value('📦'), color: const Value('#607D8B'), sortOrder: const Value(8), createdAt: now, updatedAt: now),
      ]);
      batch.insertAll(
        userSettings,
        [
          UserSettingsCompanion.insert(key: 'theme_mode', value: const Value('0'), type: const Value('int'), updatedAt: now),
          UserSettingsCompanion.insert(key: 'currency', value: const Value('€'), type: const Value('string'), updatedAt: now),
          UserSettingsCompanion.insert(key: 'default_vat_rate', value: const Value('24.0'), type: const Value('double'), updatedAt: now),
          UserSettingsCompanion.insert(key: 'receipt_number_counter', value: const Value('1'), type: const Value('int'), updatedAt: now),
          // version-stamp ΜΕΣΑ στο ίδιο batch → seed ατομικό (ένα implicit transaction).
          // insertOrReplace + unique(key) → idempotent σε re-run.
          UserSettingsCompanion.insert(key: 'seed_version', value: const Value('1'), type: const Value('int'), updatedAt: now),
        ],
        mode: InsertMode.insertOrReplace,
      );
    });
  }
  
  /// Data migrations — τρέχει σε ΥΠΑΡΧΟΥΣΑ βάση μετά από upgrade
  /// Αυτό είναι ζωτικό: όταν προσθέτουμε νέες default κατηγορίες/ρυθμίσεις,
  /// πρέπει να μπουν και σε υφιστάμενες εγκαταστάσεις (όχι μόνο νέες DBs).
  Future<void> _applyDataMigrations() async {
    final version = await _getSeedVersion();
    if (version < currentSeedVersion) { await _runSeedV1(); }
    // if (version < currentSeedVersion) { await _runSeedV2(); } // νέες νόμιμες versions
  }
  
  Future<int> _getSeedVersion() async {
    final row = await (select(userSettings)
      ..where((s) => s.key.equals('seed_version'))
    ).getSingleOrNull();
    return row != null ? int.tryParse(row.value ?? '') ?? 0 : 0;
  }
  
/// SPO: Close database connection
  @override
  Future<void> close() async {
    await super.close();
  }
}

/// SPO: Database connection factory
///
/// **Timezone:** ΕΠΙΒΑΛΛΕΤΑΙ από το `UtcDateTimeConverter` (§4.2) σε κάθε
/// DateTime column — αποθήκευση UTC, εμφάνιση local. Κανένα .toUtc() manual.
///
/// **SQLCipher (μελλοντικά):** Αν χρειαστεί κρυπτογράφηση DB, αλλάζει μόνο
/// το εσωτερικό αυτής της μεθόδου (NativeDatabase → EncryptedNativeDatabase).
/// Καμία αλλαγή στην υπόλοιπη υποδομή
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final sw = Stopwatch()..start();
    try {
      final file = await resolveDatabaseFile();

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
```

### 4.2 Drift Tables (`core/database/tables/`)

> **UUID POLICY (μελλοντικό sync / multi-device):** Κάθε "entity" πίνακας έχει
> στήλη `uuid TEXT NOT NULL UNIQUE` με `clientDefault(() => const Uuid().v4())`.
> Τα `id` (autoincrement) παραμένουν για τοπικές αναφορές/foreign keys, αλλά το
> `uuid` είναι το **global identity** — απαραίτητο για μελλοντικό cloud sync
> (χωρίς συγκρούσεις IDs μεταξύ συσκευών). Δεν βάζουμε uuid σε junction tables
> (ReceiptTags) ούτε στο UserSettings (key-based).
> Απαιτούνται σε κάθε entity table file τα imports:
> - `import 'package:uuid/uuid.dart';` (για τη στήλη uuid)
> - `import 'utc_date_time_converter.dart';` (για τα dateTime().map(const UtcDateTimeConverter())() columns)

```dart
// core/database/tables/utc_date_time_converter.dart
import 'package:drift/drift.dart';

/// SPO: UTC TypeConverter — ΕΠΙΒΑΛΛΕΙ την timezone policy στον κώδικα (όχι σε σχόλιο).
/// Αποθήκευση: πάντα UTC. Ανάγνωση: πάντα local timezone.
/// ⚠️ ΔΙΟΡΘΩΣΗ: `storeDateTimeAsText: true` αναλαμβάνει ήδη το DateTime↔String.
/// Ο drift τότε τροφοδοτεί τον converter με DateTime (όχι String), γι' αυτό
/// ο converter είναι TypeConverter<DateTime, DateTime> — χειρίζεται ΜΟΝΟ UTC↔local.
class UtcDateTimeConverter extends TypeConverter<DateTime, DateTime> {
  const UtcDateTimeConverter();
  @override
  DateTime fromSql(DateTime fromDb) => fromDb.toLocal();
  @override
  DateTime toSql(DateTime value) => value.toUtc();
}

/// ⚠️ ΔΙΟΡΘΩΣΗ: ΔΕΝ υπάρχει πια helper `utcDateTime()`.
/// Ο drift codegen ΔΕΝ υποστηρίζει function calls σε column builders
/// (σφάλμα: "type 'Null' is not a subtype of type 'MethodInvocation'").
/// Κάθε στήλη ημερομηνίας δηλώνεται INLINE:
///   Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
///
/// ⚠️ ΔΙΟΡΘΩΣΗ: ΔΕΝ χρησιμοποιούμε `withDefault(currentDateAndTime)` —
/// ο Drift εμφανίζει warning "Parameter must accept DateTime" στα mapped
/// columns. Τα createdAt/updatedAt ΔΕΝ έχουν default πλέον· ο κώδικας
/// εφαρμογής/DAO τα θέτει ρητά (DateTime.now()).
```

```dart
// core/database/tables/categories.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Categories table
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get parentId => integer().references(Categories, #id).nullable()();
  IntColumn get level => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdBy => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
  
  @override
  List<Set<Column>> get uniqueKeys => [{name, parentId}];
}

// core/database/tables/suppliers.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Suppliers table
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get vatNumber => text().nullable().unique()();
  TextColumn get taxOffice => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get website => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get postalCode => text().nullable()();
  TextColumn get country => text().withDefault(const Constant('Ελλάδα'))();
  TextColumn get bankName => text().nullable()();
  TextColumn get bankAccount => text().nullable()();
  TextColumn get iban => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/items.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'categories.dart';
import 'suppliers.dart';
import 'utc_date_time_converter.dart';

/// SPO: Items table
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('τεμ'))();
  RealColumn get unitWeight => real().nullable()();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get maxStock => real().withDefault(const Constant(0))();
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  RealColumn get reorderLevel => real().withDefault(const Constant(0))();
  RealColumn get lastPrice => real().nullable()();
  IntColumn get lastSupplierId => integer().references(Suppliers, #id).nullable()();
  IntColumn get preferredSupplierId => integer().references(Suppliers, #id).nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isTaxable => boolean().withDefault(const Constant(true))();
  RealColumn get defaultVatRate => real().withDefault(const Constant(24.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
  
  @override
  List<Set<Column>> get uniqueKeys => [{name, categoryId}];
}

// core/database/tables/receipts.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'suppliers.dart';
import 'utc_date_time_converter.dart';

/// SPO: Receipts table
class Receipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptNumber => integer().unique()();
  Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get invoiceSeries => text().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get vatTotal => real().withDefault(const Constant(0))();
  RealColumn get discountTotal => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  TextColumn get notes => text().nullable()();
  TextColumn get attachmentPath => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/receipt_items.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'receipts.dart';
import 'items.dart';
import 'utc_date_time_converter.dart';

/// SPO: Receipt items table
class ReceiptItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptId => integer().references(Receipts, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
  RealColumn get vatRate => real().withDefault(const Constant(24.0))();
  RealColumn get vatAmount => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get totalPrice => real()();
  RealColumn get totalWithVat => real()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/payments.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'receipts.dart';
import 'utc_date_time_converter.dart';

/// SPO: Payments table
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get receiptId => integer().references(Receipts, #id)();
  RealColumn get amount => real()();
  Column<DateTime> get paymentDate => dateTime().map(const UtcDateTimeConverter())();
  TextColumn get paymentMethod => text()();
  TextColumn get reference => text().nullable()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/price_history.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'items.dart';
import 'suppliers.dart';
import 'utc_date_time_converter.dart';

/// SPO: Price history table
class PriceHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  IntColumn get itemId => integer().references(Items, #id)();
  RealColumn get price => real()();
  RealColumn get vatRate => real().withDefault(const Constant(24.0))();
  Column<DateTime> get receiptDate => dateTime().map(const UtcDateTimeConverter())();
  IntColumn get supplierId => integer().references(Suppliers, #id)();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/budgets.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'categories.dart';
import 'utc_date_time_converter.dart';

/// SPO: Budgets table
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  // NOT NULL: κάθε budget ανήκει σε κατηγορία - δεν υπάρχει "γενικό budget".
  // Αν χρειαστεί γενικό budget, υπολογίζεται ως άθροισμα των category budgets.
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  // Σημείωση: NO spentAmount - το spent υπολογίζεται LIVE μέσω aggregate query στο BudgetDao
  // (δεν αποθηκεύουμε derived/aggregate τιμές που μπορεί να γίνουν stale)
  RealColumn get amount => real()();
  TextColumn get notes => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
  
  @override
  List<Set<Column>> get uniqueKeys => [{categoryId, month, year}];
}

// core/database/tables/tags.dart
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'utc_date_time_converter.dart';

/// SPO: Tags table
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().clientDefault(() => const Uuid().v4()).unique()();
  TextColumn get name => text().unique()();
  TextColumn get color => text().nullable()();
  Column<DateTime> get createdAt => dateTime().map(const UtcDateTimeConverter())();
}

// core/database/tables/receipt_tags.dart
import 'package:drift/drift.dart';
import 'receipts.dart';
import 'tags.dart';

/// SPO: Receipt tags junction table
class ReceiptTags extends Table {
  IntColumn get receiptId => integer().references(Receipts, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  
  @override
  Set<Column> get primaryKey => {receiptId, tagId};
}

// core/database/tables/user_settings.dart
import 'package:drift/drift.dart';
import 'utc_date_time_converter.dart';

/// SPO: User settings table
class UserSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('string'))();
  Column<DateTime> get updatedAt => dateTime().map(const UtcDateTimeConverter())();
}
```
---

