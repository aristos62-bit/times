### 4.3c DAOs — Supplier/Tag/Setting (συνέχεια του §4.3)

> SPLIT (12/09/2026): συνέχεια του `design/05_daos.md`. Η εισαγωγή (§4.3,
> πίνακας DAO, αποκλίσεις, διορθώσεις) και ο οδηγός `ReceiptDao` στο
> `05_daos.md`· `BudgetDao`/`ItemDao`/`CategoryDao` στο `05_daos_budget_item.md`.

```dart
// core/database/daos/supplier_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'supplier_dao.g.dart';

/// SPO: Supplier Data Access Object
@DriftAccessor(tables: [Suppliers, Receipts])
class SupplierDao extends DatabaseAccessor<AppDatabase> with _$SupplierDaoMixin {
  SupplierDao(super.db);

  /// Watch all active suppliers (reactive)
  Stream<List<Supplier>> watchAllSuppliers() {
    return (select(suppliers)
      ..where((s) => s.isActive.equals(true))
      ..orderBy([(s) => OrderingTerm.asc(s.name)])
    ).watch();
  }

  /// Search suppliers by name (LIKE query, reactive)
  Stream<List<Supplier>> searchSuppliersByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(suppliers)
      ..where((s) => s.isActive.equals(true) & s.name.lower().like(pattern))
      ..orderBy([(s) => OrderingTerm.asc(s.name)])
    ).watch();
  }

  /// Get supplier by id
  Future<Supplier?> getSupplierById(int id) =>
      (select(suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();

  /// Create supplier
  Future<int> createSupplier(SuppliersCompanion companion) =>
      into(suppliers).insert(companion);

  /// Update supplier
  Future<bool> updateSupplier(SuppliersCompanion companion) =>
      update(suppliers).replace(companion);

  /// Soft delete (isActive = false)
  Future<void> softDeleteSupplier(int id) async {
    await (update(suppliers)..where((s) => s.id.equals(id)))
        .write(SuppliersCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
  }

  /// Πλήθος αποδείξεων ενός προμηθευτή (για UI badges / στοιχεία ασφαλείας)
  Future<int> getReceiptCount(int id) async {
    final row = await (customSelect(
      'SELECT COUNT(*) as count FROM receipts WHERE supplier_id = ?',
      variables: [Variable.withInt(id)],
      readsFrom: {receipts},
    ))
        .getSingle();
    return row.read<int>('count');
  }
}
```
```dart
// core/database/daos/tag_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'tag_dao.g.dart';

/// SPO: Tag Data Access Object (tags + receipt_tags)
@DriftAccessor(tables: [Tags, ReceiptTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  /// Watch all tags (reactive)
  Stream<List<Tag>> watchAllTags() {
    return (select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// Search tags by name (LIKE, reactive)
  Stream<List<Tag>> searchTagsByName(String query) {
    final pattern = '%${query.toLowerCase()}%';
    return (select(tags)
      ..where((t) => t.name.lower().like(pattern))
      ..orderBy([(t) => OrderingTerm.asc(t.name)])
    ).watch();
  }

  /// Get tag by id
  Future<Tag?> getTagById(int id) =>
      (select(tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Create tag (αν υπάρχει ήδη με το ίδιο name → null / UNIQUE constraint)
  /// ΣΗΜΕΙΩΣΗ: insertReturningOrNull + insertOrIgnore = upsert με εισαγωγή
  /// timestamp δημιουργίας. Δεν χρησιμοποιείται insertOnConflictUpdate γιατί
  /// δεν θες mirror-update σε duplicate.
  Future<Tag?> createTag(String name, {String? color}) =>
      into(tags).insertReturningOrNull(
        TagsCompanion.insert(
          name: name,
          color: Value(color),
          createdAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Update tag
  Future<bool> updateTag(TagsCompanion companion) =>
      update(tags).replace(companion);

  /// Delete tag (αφαιρεί και τις ενώσεις receipt_tags)
  Future<void> deleteTag(int id) async {
    await transaction(() async {
      await (delete(receiptTags)..where((rt) => rt.tagId.equals(id))).go();
      await (delete(tags)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Tags ενός receipt (reactive)
  Stream<List<Tag>> watchTagsByReceiptId(int receiptId) {
    final query = select(receiptTags).join([
      innerJoin(tags, tags.id.equalsExp(receiptTags.tagId)),
    ])
      ..where(receiptTags.receiptId.equals(receiptId))
      ..orderBy([OrderingTerm.asc(tags.name)]);
    return query.watch().map((rows) => rows.map((r) => r.readTable(tags)).toList());
  }

  /// Προσθήκη tag σε receipt (idempotent)
  Future<void> addTagToReceipt(int receiptId, int tagId) async {
    await into(receiptTags).insert(
      ReceiptTagsCompanion.insert(receiptId: receiptId, tagId: tagId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Αφαίρεση tag από receipt
  Future<void> removeTagFromReceipt(int receiptId, int tagId) async {
    await (delete(receiptTags)
      ..where((rt) => rt.receiptId.equals(receiptId) & rt.tagId.equals(tagId))
    ).go();
  }

  /// Αφαίρεση όλων των tags ενός receipt
  Future<void> removeAllTagsFromReceipt(int receiptId) async {
    await (delete(receiptTags)
      ..where((rt) => rt.receiptId.equals(receiptId))
    ).go();
  }
}
```
```dart
// core/database/daos/setting_dao.dart
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'setting_dao.g.dart';

/// SPO: User settings Data Access Object
/// SPoT αποθήκευσης ρυθμίσεων (π.χ. theme). Η UserSettings table είναι
/// η ΜΟΝΗ πηγή αλήθειας — κανένα SharedPreferences για theme.
@DriftAccessor(tables: [UserSettings])
class SettingDao extends DatabaseAccessor<AppDatabase> with _$SettingDaoMixin {
  SettingDao(super.db);

  static const themeKey = 'theme_mode';

  /// Read a setting by key (as string, nullable)
  Future<String?> getSetting(String key) async {
    final row = await (select(userSettings)
      ..where((s) => s.key.equals(key))
    ).getSingleOrNull();
    return row?.value;
  }

  /// Write a setting by key (upsert)
  /// DIOORTH 2026-09-10: DoUpdate (όχι insertOrReplace) — σε αντίθετη
  /// περίπτωση το UNIQUE conflict έκανε DELETE+INSERT (νέο id κάθε φορά).
  Future<void> setSetting(String key, String value, {String type = 'string'}) async {
    final now = DateTime.now();
    await into(userSettings).insert(
      UserSettingsCompanion.insert(
        key: key,
        value: Value(value),
        type: Value(type),
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => UserSettingsCompanion(
          value: Value(value),
          type: Value(type),
          updatedAt: Value(now),
        ),
        target: [userSettings.key],
      ),
    );
  }

  /// Watch a setting by key (reactive stream)
  Stream<String?> watchSetting(String key) {
    return (select(userSettings)
      ..where((s) => s.key.equals(key))
    ).watchSingleOrNull().map((row) => row?.value);
  }

  // --- Theme helpers ---

  /// Watch theme mode (reactive) — null/άκυρο → system
  Stream<ThemeMode?> watchThemeMode() => watchSetting(themeKey).map(_parseThemeMode);

  /// Φόρτωση theme mode (single-shot για το startup)
  Future<ThemeMode> getThemeMode() async {
    final value = await getSetting(themeKey);
    return _parseThemeMode(value) ?? ThemeMode.system;
  }

  /// Αποθήκευση theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await setSetting(themeKey, '${mode.index}', type: 'int');
  }

  /// '0'=system, '1'=light, '2'=dark (ή null όταν δεν υπάρχει/άκυρο)
  ThemeMode? _parseThemeMode(String? value) {
    if (value == null) return null;
    final index = int.tryParse(value);
    if (index == null || index < 0 || index >= ThemeMode.values.length) {
      return null;
    }
    return ThemeMode.values[index];
  }
}
```
---

