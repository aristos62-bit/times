/// Orchestrator seed — Refactor 4 επιπέδων 27-09-2026.
///
/// Εκτελείται μία φορά στο `onCreate` (νέο DB file): μονάδες + κατάλογος
/// 3 επιπέδων (κατηγορίες/υποκατηγορίες/τμήματα) από τα seed constants.
/// Είδη ΔΕΝ seed-άρονται (απόφαση 27-09-2026). Τα δεδομένα καταλόγου θα
/// έρθουν από το νέο `.md` του χρήστη (Βήμα Β4β) — μέχρι τότε ο κατάλογος
/// μένει άδειος (μόνο μονάδες) και χτίζεται από το UI.
///
/// Όλο το σώμα τυλίγεται σε **ένα transaction**: αποτυχία → πλήρες rollback.
/// Fail-fast: διπλότυπο normalized όνομα (global UNIQUE §3) → `StateError`
/// με το composite key `κατηγορία|υποκατηγορία|τμήμα`.
library;

import 'package:drift/drift.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/utils/greek_text_normalizer.dart';
import '../app_database.dart';
import 'seed_types.dart';
import 'seed_units.dart';

/// Κατηγορίες seed — θα γεμίσουν από το νέο `.md` (Βήμα Β4β).
const List<CategorySeed> seedCategories = <CategorySeed>[];

/// Υποκατηγορίες seed — θα γεμίσουν από το νέο `.md` (Βήμα Β4β).
const List<SubCategorySeed> seedSubCategories = <SubCategorySeed>[];

/// Τμήματα seed — θα γεμίσουν από το νέο `.md` (Βήμα Β4β).
const List<ItemGroupSeed> seedItemGroups = <ItemGroupSeed>[];

/// Τρέχει το seed μία φορά στο `AppDatabase.onCreate`.
///
/// Κλήση: `if (!skipSeed) await runSeed(db);` — αμέσως μετά το
/// `m.createAll()`. Όλο το σώμα τυλίγεται σε **ένα transaction**.
Future<void> runSeed(AppDatabase db) => db.transaction(() async {
  AppLogger.info(
    LogTag.db,
    'Seed: ξεκίνημα (${seedUnits.length} μονάδες, '
    '${seedCategories.length} κατηγορίες, '
    '${seedSubCategories.length} υποκατηγορίες, '
    '${seedItemGroups.length} τμήματα, 0 είδη)',
  );

  // ── Μονάδες μέτρησης ────────────────────────────────────────────────────
  final unitIds = <String, int>{};
  for (final u in seedUnits) {
    final id = await db
        .into(db.units)
        .insert(
          UnitsCompanion.insert(
            name: u.name,
            abbreviation: u.abbreviation,
            allowsDecimal: Value(u.allowsDecimal),
          ),
        );
    unitIds[GreekTextNormalizer.normalize(u.name)] = id;
  }
  AppLogger.info(LogTag.db, 'Seed: μονάδες → ${unitIds.length}');

  // ── Κατηγορίες ─────────────────────────────────────────────────────────
  final categoryIds = <String, int>{};
  for (final c in seedCategories) {
    final key = GreekTextNormalizer.normalize(c.name);
    if (categoryIds.containsKey(key)) {
      throw StateError('Seed: διπλή κατηγορία "${c.name}"');
    }
    final id = await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name: c.name,
            normalizedName: key,
          ),
        );
    categoryIds[key] = id;
  }
  AppLogger.info(LogTag.db, 'Seed: κατηγορίες → ${categoryIds.length}');

  // ── Υποκατηγορίες ──────────────────────────────────────────────────────
  final subCategoryIds = <String, int>{};
  for (final s in seedSubCategories) {
    final key = GreekTextNormalizer.normalize(s.name);
    if (subCategoryIds.containsKey(key)) {
      throw StateError('Seed: διπλή υποκατηγορία "${s.name}"');
    }
    final catId = categoryIds[GreekTextNormalizer.normalize(s.categoryName)];
    if (catId == null) {
      throw StateError(
        'Seed: άγνωστη κατηγορία "${s.categoryName}" '
        'για υποκατηγορία "${s.name}"',
      );
    }
    final id = await db.into(db.subCategories).insert(
          SubCategoriesCompanion.insert(
            name: s.name,
            normalizedName: key,
            categoryId: catId,
          ),
        );
    subCategoryIds[key] = id;
  }
  AppLogger.info(LogTag.db, 'Seed: υποκατηγορίες → ${subCategoryIds.length}');

  // ── Τμήματα ────────────────────────────────────────────────────────────
  final groupNames = <String>{};
  var groupCount = 0;
  for (final g in seedItemGroups) {
    final key = GreekTextNormalizer.normalize(g.name);
    if (groupNames.contains(key)) {
      throw StateError('Seed: διπλό τμήμα "${g.name}"');
    }
    final subId = subCategoryIds[GreekTextNormalizer.normalize(g.subCategoryName)];
    if (subId == null) {
      throw StateError(
        'Seed: άγνωστη υποκατηγορία "${g.subCategoryName}" '
        'για τμήμα "${g.name}"',
      );
    }
    await db.into(db.itemGroups).insert(
          ItemGroupsCompanion.insert(
            name: g.name,
            normalizedName: key,
            subCategoryId: subId,
          ),
        );
    groupNames.add(key);
    groupCount++;
  }
  AppLogger.info(LogTag.db, 'Seed: τμήματα → $groupCount (ολοκληρώθηκε)');
});
