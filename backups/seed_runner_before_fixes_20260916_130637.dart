/// Orchestrator seed — Φάση 1, Βήμα 3.
///
/// Εκτελείται μία φορά στο `onCreate` (νέο DB file). Χρησιμοποιεί
/// `db.into(table).insert(...)` — το `into` είναι μέθοδος του `AppDatabase`
/// μέσω `DatabaseConnectionUser`· ο `Migrator` δεν χρειάζεται.
/// Όλες οι αναφορές γίνονται με **ονόματα** (record fields), όχι IDs.
library;

import 'package:drift/drift.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/utils/greek_text_normalizer.dart';
import '../app_database.dart';
import 'seed_categories.dart';
import 'seed_items_brefika.dart';
import 'seed_items_hlektrika.dart';
import 'seed_items_kapnika.dart';
import 'seed_items_katharistika.dart';
import 'seed_items_katikidia.dart';
import 'seed_items_pota.dart';
import 'seed_items_prwswpiki_ygieini.dart';
import 'seed_items_trofima.dart';
import 'seed_items_xartika.dart';
import 'seed_sub_categories.dart';
import 'seed_types.dart';
import 'seed_units.dart';

/// Συνολική λίστα ειδών (συνένωση όλων των 9 κατηγοριών).
final List<ItemSeed> seedItems = <ItemSeed>[
  ...seedItemsTrofima,
  ...seedItemsPota,
  ...seedItemsPrwswpikiYgieini,
  ...seedItemsKatharistika,
  ...seedItemsXartika,
  ...seedItemsBrefika,
  ...seedItemsKatikidia,
  ...seedItemsHlektrika,
  ...seedItemsKapnika,
];

/// Τρέχει το seed μονά μία φορά στο `AppDatabase.onCreate`.
///
/// Κλήση: `if (!skipSeed) await runSeed(db);` — αμέσως μετά το
/// `m.createAll()`. Αποτυχία → exception → ολόκληρο το DB αναστέλλεται
/// ατομικά (Drift transaction στο onCreate).
Future<void> runSeed(AppDatabase db) async {
  AppLogger.info(
    LogTag.db,
    'Seed: ξεκίνημα (5 μονάδες, 9 κατηγορίες, 53 υποκατηγορίες, '
    '${seedItems.length} είδη)',
  );

  // ── Μονάδες μέτρησης ────────────────────────────────────────────────────
  final unitIds = <String, int>{};
  for (final u in seedUnits) {
    final id = await db.into(db.units).insert(
      UnitsCompanion.insert(
        name: u.name,
        abbreviation: u.abbreviation,
        allowsDecimal: Value(u.allowsDecimal),
      ),
    );
    unitIds[u.name] = id;
  }
  AppLogger.info(LogTag.db, 'Seed: μονάδες → ${unitIds.length}');

  // ── Κατηγορίες ─────────────────────────────────────────────────────────
  final categoryIds = <String, int>{};
  for (final c in seedCategories) {
    final id = await db.into(db.categories).insert(
      CategoriesCompanion.insert(name: c.name),
    );
    categoryIds[c.name] = id;
  }
  AppLogger.info(LogTag.db, 'Seed: κατηγορίες → ${categoryIds.length}');

  // ── Υποκατηγορίες ───────────────────────────────────────────────────────
  final subCategoryIds = <String, int>{};
  for (final s in seedSubCategories) {
    final catId = categoryIds[s.categoryName];
    if (catId == null) {
      throw StateError(
        'Seed: αγνώστη κατηγορία "${s.categoryName}" '
        'για υποκατηγορία "${s.name}"',
      );
    }
    final id = await db.into(db.subCategories).insert(
      SubCategoriesCompanion.insert(name: s.name, categoryId: catId),
    );
    subCategoryIds[s.name] = id;
  }
  AppLogger.info(LogTag.db, 'Seed: υποκατηγορίες → ${subCategoryIds.length}');

  // ── Είδη ────────────────────────────────────────────────────────────────
  for (final item in seedItems) {
    final subCatId = subCategoryIds[item.subCategoryName];
    if (subCatId == null) {
      throw StateError(
        'Seed: αγνώστη υποκατηγορία "${item.subCategoryName}" '
        'για είδος "${item.name}"',
      );
    }

    Value<int> defaultUnitId;
    if (item.defaultUnitName != null) {
      final uid = unitIds[item.defaultUnitName];
      if (uid == null) {
        throw StateError(
          'Seed: αγνώστη μονάδα "${item.defaultUnitName}" '
          'για είδος "${item.name}"',
        );
      }
      defaultUnitId = Value(uid);
    } else {
      defaultUnitId = const Value.absent();
    }

    await db.into(db.items).insert(
      ItemsCompanion.insert(
        name: item.name,
        normalizedName: GreekTextNormalizer.normalize(item.name),
        subCategoryId: subCatId,
        defaultUnitId: defaultUnitId,
      ),
    );
  }
  AppLogger.info(LogTag.db, 'Seed: είδη → ${seedItems.length} (ολοκληρώθηκε)');
}