/// Unit tests — `ItemManagementController` (§2.3 · ενότητα Ειδών · 4 επίπεδα).
///
/// update (ok/no-op/dup/missing/unit/move) · delete (ok/blocked/missing +
/// καθάρισμα επιλογής) · refreshGuards. `ProviderContainer.test()` +
/// in-memory DB (pattern supplier controller test).
///
/// Το είδος ανήκει σε ΤΜΗΜΑ (`itemGroupId` — 27-09-2026): η μετακίνηση
/// ανανεώνει τις πύλες παλιού + νέου τμήματος ΚΑΙ των γονικών
/// υποκατηγοριών/κατηγοριών (2-hop guard refresh).
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/constants/app_errors.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/providers/database_providers.dart';
import 'package:times/data/providers/settings_providers.dart';
import 'package:times/presentation/price_entry/controllers/item_search_controller.dart';
import 'package:times/presentation/settings/controllers/item_management_controller.dart';

import '../../../data/local/helpers/in_memory_db.dart';

void main() {
  late AppDatabase db;

  late int itemId;
  late int groupId;
  late int subId;
  late int categoryId;
  late int unitId;

  setUp(() async {
    db = inMemoryDb();
    addTearDown(db.close);
    unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    groupId = await ItemGroupDao(
      db,
    ).insert(subCategoryId: subId, name: 'Φρέσκα');
    itemId = await ItemDao(db).insert(itemGroupId: groupId, name: 'Γάλα');
  });

  ProviderContainer container() => ProviderContainer.test(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );

  group('ItemManagementController.updateItem', () {
    test('rename ΟΚ + dup/κενό/ανύπαρκτο', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(itemManagementControllerProvider.notifier);

      var result = await notifier.updateItem(
        id: itemId,
        name: 'Γάλα φρέσκο',
        itemGroupId: groupId,
      );
      expect(result.ok, isTrue);
      expect(await ItemDao(db).getById(itemId), isNotNull);

      // no-op (ίδια τιμή, χωρίς Value) → ok χωρίς write.
      result = await notifier.updateItem(
        id: itemId,
        name: 'Γάλα φρέσκο',
        itemGroupId: groupId,
      );
      expect(result.ok, isTrue);

      // Κενό → nameRequired.
      result = await notifier.updateItem(
        id: itemId,
        name: '   ',
        itemGroupId: groupId,
      );
      expect(result.ok, isFalse);
      expect(result.error, AppErrors.nameRequired);

      // Ανύπαρκτο id → loadDataFailed.
      result = await notifier.updateItem(
        id: 9999,
        name: 'Χ',
        itemGroupId: groupId,
      );
      expect(result.ok, isFalse);
      expect(result.error, AppErrors.loadDataFailed);
    });

    test('dup προς άλλο είδος → nameExists (εαυτός εξαιρείται)', () async {
      final otherId = await ItemDao(
        db,
      ).insert(itemGroupId: groupId, name: 'Τυρί');
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(itemManagementControllerProvider.notifier);

      // Αλλαγή μόνο τόνων στον εαυτό → γράφεται (όχι dup).
      var result = await notifier.updateItem(
        id: itemId,
        name: 'ΓΑΛΑ',
        itemGroupId: groupId,
      );
      expect(result.ok, isTrue);

      // Όνομα άλλου → nameExists.
      result = await notifier.updateItem(
        id: otherId,
        name: 'γάλα',
        itemGroupId: groupId,
      );
      expect(result.ok, isFalse);
      expect(result.error, AppErrors.nameExists);
    });

    test('defaultUnitId: θέτει + καθαρίζει (Value pattern)', () async {
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(itemManagementControllerProvider.notifier);

      var result = await notifier.updateItem(
        id: itemId,
        name: 'Γάλα',
        itemGroupId: groupId,
        defaultUnitId: Value(unitId),
      );
      expect(result.ok, isTrue);
      expect((await ItemDao(db).getById(itemId))!.defaultUnitId, unitId);

      result = await notifier.updateItem(
        id: itemId,
        name: 'Γάλα',
        itemGroupId: groupId,
        defaultUnitId: const Value(null),
      );
      expect(result.ok, isTrue);
      expect((await ItemDao(db).getById(itemId))!.defaultUnitId, isNull);
    });

    test('μετακίνηση τμήματος ανανεώνει πύλες 2-hop (group+sub+cat)',
        () async {
      final otherGroupId = await ItemGroupDao(
        db,
      ).insert(subCategoryId: subId, name: 'Κατεψυγμένα');
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(itemManagementControllerProvider.notifier);

      final result = await notifier.updateItem(
        id: itemId,
        name: 'Γάλα',
        itemGroupId: otherGroupId,
      );
      expect(result.ok, isTrue);
      expect((await ItemDao(db).getById(itemId))!.itemGroupId, otherGroupId);
      // Οι πύλες νέου + παλιού τμήματος ξανατρέχουν (invalidate) — καθαρές.
      expect(
        await c.read(canDeleteItemGroupProvider(otherGroupId).future),
        isTrue,
      );
      expect(await c.read(canDeleteItemGroupProvider(groupId).future), isTrue);
      // 2-hop: η γονική υποκατηγορία + κατηγορία παραμένουν καθαρές.
      expect(await c.read(canDeleteSubCategoryProvider(subId).future), isTrue);
      expect(
        await c.read(canDeleteCategoryProvider(categoryId).future),
        isTrue,
      );
    });

    test('μετακίνηση σε τμήμα άλλης υποκατηγορίας/κατηγορίας', () async {
      final otherCat = await CategoryDao(db).insert(name: 'ΟΙΚΙΑΚΑ');
      final otherSub = await SubCategoryDao(
        db,
      ).insert(categoryId: otherCat, name: 'Καθαριστικά');
      final otherGroup = await ItemGroupDao(
        db,
      ).insert(subCategoryId: otherSub, name: 'Υγρά');
      final c = container();
      addTearDown(c.dispose);
      final notifier = c.read(itemManagementControllerProvider.notifier);

      final result = await notifier.updateItem(
        id: itemId,
        name: 'Γάλα',
        itemGroupId: otherGroup,
      );
      expect(result.ok, isTrue);
      expect((await ItemDao(db).getById(itemId))!.itemGroupId, otherGroup);
      // Παλιό δέντρο άδειο + καθαρό, νέο καθαρό.
      expect(await c.read(canDeleteItemGroupProvider(groupId).future), isTrue);
      expect(await c.read(canDeleteItemGroupProvider(otherGroup).future), isTrue);
      expect(await c.read(canDeleteSubCategoryProvider(subId).future), isTrue);
      expect(
        await c.read(canDeleteSubCategoryProvider(otherSub).future),
        isTrue,
      );
    });
  });

  group('ItemManagementController.deleteItem', () {
    test('καθαρό → ok + εξαφανίζεται', () async {
      final c = container();
      addTearDown(c.dispose);
      final result = await c
          .read(itemManagementControllerProvider.notifier)
          .deleteItem(itemId);
      expect(result.ok, isTrue);
      expect(await ItemDao(db).getById(itemId), isNull);
    });

    test('με γραμμές → blocked tooltip (όχι delete)', () async {
      final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
      final receiptId = await ReceiptDao(db).insert(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
      );
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 100,
      );
      final c = container();
      addTearDown(c.dispose);
      final result = await c
          .read(itemManagementControllerProvider.notifier)
          .deleteItem(itemId);
      expect(result.ok, isFalse);
      expect(await ItemDao(db).getById(itemId), isNotNull);
    });

    test('ανύπαρκτο → loadDataFailed', () async {
      final c = container();
      addTearDown(c.dispose);
      final result = await c
          .read(itemManagementControllerProvider.notifier)
          .deleteItem(9999);
      expect(result.ok, isFalse);
      expect(result.error, AppErrors.loadDataFailed);
    });

    test('καθαρίζει root επιλογή του σβησμένου', () async {
      final c = container();
      addTearDown(c.dispose);
      final item = await ItemDao(db).getById(itemId);
      c.read(itemSearchControllerProvider.notifier).selectItem(item!);
      await c
          .read(itemManagementControllerProvider.notifier)
          .deleteItem(itemId);
      expect(
        c.read(itemSearchControllerProvider).value?.selectedItem,
        isNull,
      );
    });
  });

  group('ItemManagementController.refreshGuards', () {
    test('τρέχει χωρίς σφάλμα', () {
      final c = container();
      addTearDown(c.dispose);
      c
          .read(itemManagementControllerProvider.notifier)
          .refreshGuards(itemIds: [itemId]);
    });
  });
}
