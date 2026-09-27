/// Unit tests για τα counts + cascade του `CategoryDao`
/// (Refactor 4 επιπέδων 27-09-2026 · §2.3).
///
/// Αλυσίδες cat → sub → group → item σε κάθε test. Ελέγχει:
/// `countItemsByCategoryId` (0/N + απομόνωση ξένης κατηγορίας, 3 joins),
/// `countItemsInUseByCategoryId` (0/DISTINCT + απομόνωση),
/// `deleteWithContents` (άδεια/με περιεχόμενα/ανύπαρκτη + ατομικότητα σε
/// μπλοκαρισμένη με 2 subs). Σειρά cascade: είδη → τμήματα → subs → cat.
/// Τα σφάλματα FK είναι raw (όχι AppException) — mapping στο Repository.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late CategoryDao dao;

  setUp(() {
    db = inMemoryDb();
    dao = CategoryDao(db);
  });

  tearDown(() async => await db.close());

  /// Δημιουργεί μονάδα + προμηθευτή (απαραίτητα για γραμμές απόδειξης).
  Future<({int unitId, int supplierId})> seedUnitAndSupplier() async {
    final unitId =
        await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    return (unitId: unitId, supplierId: supplierId);
  }

  /// Δημιουργεί τμήμα κάτω από την υποκατηγορία [subId].
  Future<int> seedGroup(int subId, String name) =>
      ItemGroupDao(db).insert(subCategoryId: subId, name: name);

  /// Δημιουργεί είδος μέσα στο τμήμα [groupId].
  Future<int> seedItem(int groupId, String name, {int? unitId}) =>
      ItemDao(db).insert(itemGroupId: groupId, name: name, defaultUnitId: unitId);

  /// Δημιουργεί απόδειξη + γραμμή για το είδος.
  Future<void> seedReceiptLine({
    required int itemId,
    required int unitId,
    required int supplierId,
  }) async {
    final receiptId = await ReceiptDao(db)
        .insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
    await ReceiptLineDao(db).insert(
      receiptId: receiptId,
      itemId: itemId,
      unitId: unitId,
      quantity: 1,
      priceCents: 100,
    );
  }

  group('CategoryDao.countItemsByCategoryId', () {
    test('άδεια κατηγορία (με κενό τμήμα) → 0', () async {
      final categoryId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      await seedGroup(subId, 'Φέτα');

      expect(await dao.countItemsByCategoryId(categoryId), 0);
    });

    test('μετράει είδη από όλες τις υποκατηγορίες/τμήματα', () async {
      final categoryId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subDao = SubCategoryDao(db);
      final sub1 =
          await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final sub2 =
          await subDao.insert(categoryId: categoryId, name: 'Αρτοποιήματα');
      final group1 = await seedGroup(sub1, 'Φέτα');
      final group2 = await seedGroup(sub2, 'Ψωμιά');
      await seedItem(group1, 'Γάλα');
      await seedItem(group2, 'Ψωμί');
      await seedItem(group2, 'Κουλούρι');

      expect(await dao.countItemsByCategoryId(categoryId), 3);
    });

    test('απομονώνει ξένη κατηγορία', () async {
      final foodId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final homeId = await dao.insert(name: 'ΟΙΚΙΑΚΑ');
      final subDao = SubCategoryDao(db);
      final foodSub =
          await subDao.insert(categoryId: foodId, name: 'Γαλακτοκομικά');
      final homeSub =
          await subDao.insert(categoryId: homeId, name: 'Καθαριότητα');
      final foodGroup = await seedGroup(foodSub, 'Φέτα');
      final homeGroup = await seedGroup(homeSub, 'Απορρυπαντικά');
      await seedItem(foodGroup, 'Γάλα');
      await seedItem(homeGroup, 'Σφουγγάρι');

      expect(await dao.countItemsByCategoryId(foodId), 1);
      expect(await dao.countItemsByCategoryId(homeId), 1);
    });
  });

  group('CategoryDao.countItemsInUseByCategoryId', () {
    test('είδη χωρίς γραμμές → 0', () async {
      final categoryId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final groupId = await seedGroup(subId, 'Φέτα');
      await seedItem(groupId, 'Γάλα');

      expect(await dao.countItemsInUseByCategoryId(categoryId), 0);
    });

    test('είδος με 2 γραμμές μετριέται μία φορά (DISTINCT)', () async {
      final seed = await seedUnitAndSupplier();
      final categoryId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final groupId = await seedGroup(subId, 'Φέτα');
      final itemId = await seedItem(groupId, 'Γάλα');
      await seedReceiptLine(
        itemId: itemId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );
      await seedReceiptLine(
        itemId: itemId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(await dao.countItemsInUseByCategoryId(categoryId), 1);
    });

    test('απομονώνει ξένη κατηγορία', () async {
      final seed = await seedUnitAndSupplier();
      final foodId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final homeId = await dao.insert(name: 'ΟΙΚΙΑΚΑ');
      final subDao = SubCategoryDao(db);
      final foodSub =
          await subDao.insert(categoryId: foodId, name: 'Γαλακτοκομικά');
      final homeSub =
          await subDao.insert(categoryId: homeId, name: 'Καθαριότητα');
      final foodGroup = await seedGroup(foodSub, 'Φέτα');
      final homeGroup = await seedGroup(homeSub, 'Απορρυπαντικά');
      final milkId = await seedItem(foodGroup, 'Γάλα');
      await seedItem(homeGroup, 'Σφουγγάρι');
      await seedReceiptLine(
        itemId: milkId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(await dao.countItemsInUseByCategoryId(foodId), 1);
      expect(await dao.countItemsInUseByCategoryId(homeId), 0);
    });
  });

  group('CategoryDao.deleteWithContents', () {
    test('άδεια κατηγορία → true και εξαφανίζεται', () async {
      final categoryId = await dao.insert(name: 'ΠΡΟΣ ΔΙΑΓΡΑΦΗ');

      expect(await dao.deleteWithContents(categoryId), isTrue);
      expect(await dao.getById(categoryId), isNull);
    });

    test('με subs+τμήματα+items χωρίς γραμμές → σβήνει όλα, οι μονάδες μένουν',
        () async {
      final seed = await seedUnitAndSupplier();
      final categoryId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subDao = SubCategoryDao(db);
      final groupDao = ItemGroupDao(db);
      final itemDao = ItemDao(db);
      final sub1 =
          await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final sub2 =
          await subDao.insert(categoryId: categoryId, name: 'Αρτοποιήματα');
      final group1 = await seedGroup(sub1, 'Φέτα');
      final group2 = await seedGroup(sub2, 'Ψωμιά');
      final milkId = await seedItem(group1, 'Γάλα', unitId: seed.unitId);
      final breadId = await seedItem(group2, 'Ψωμί');

      expect(await dao.deleteWithContents(categoryId), isTrue);
      expect(await dao.getById(categoryId), isNull);
      expect(await subDao.getById(sub1), isNull);
      expect(await subDao.getById(sub2), isNull);
      expect(await groupDao.getById(group1), isNull);
      expect(await groupDao.getById(group2), isNull);
      expect(await itemDao.getById(milkId), isNull);
      expect(await itemDao.getById(breadId), isNull);
      // Οι μονάδες δεν αγγίζονται (SET NULL, όχι cascade).
      expect(await UnitDao(db).getById(seed.unitId), isNotNull);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.deleteWithContents(999), isFalse);
    });

    test('μπλοκαρισμένη (2 subs, η 2η με γραμμές) → throw + rollback',
        () async {
      final seed = await seedUnitAndSupplier();
      final categoryId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subDao = SubCategoryDao(db);
      final groupDao = ItemGroupDao(db);
      final itemDao = ItemDao(db);
      final sub1 =
          await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final sub2 =
          await subDao.insert(categoryId: categoryId, name: 'Αρτοποιήματα');
      final group1 = await seedGroup(sub1, 'Φέτα');
      final group2 = await seedGroup(sub2, 'Ψωμιά');
      final milkId = await seedItem(group1, 'Γάλα');
      final breadId = await seedItem(group2, 'Ψωμί');
      await seedReceiptLine(
        itemId: breadId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      // RESTRICT: raw σφάλμα (ποτέ AppException) + πλήρες rollback.
      await expectLater(
        dao.deleteWithContents(categoryId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await dao.getById(categoryId), isNotNull);
      expect(await subDao.getById(sub1), isNotNull);
      expect(await subDao.getById(sub2), isNotNull);
      expect(await groupDao.getById(group1), isNotNull);
      expect(await groupDao.getById(group2), isNotNull);
      expect(await itemDao.getById(milkId), isNotNull);
      expect(await itemDao.getById(breadId), isNotNull);
      expect(await db.select(db.receiptLines).get(), hasLength(1));
    });
  });
}
