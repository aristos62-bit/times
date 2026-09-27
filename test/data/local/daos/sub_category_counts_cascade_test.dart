/// Unit tests για τα counts + cascade του `SubCategoryDao`
/// (Refactor 4 επιπέδων 27-09-2026 · §2.3).
///
/// Αλυσίδες sub → group → item σε κάθε test. Ελέγχει:
/// `countItemsBySubCategoryId` (0/N + απομόνωση ξένης υποκατηγορίας,
/// 2 joins), `countItemsInUseBySubCategoryId` (0/DISTINCT + απομόνωση),
/// `deleteWithContents` (κενή/με είδη/ανύπαρκτη + ατομικότητα σε
/// μπλοκαρισμένη). Σειρά cascade: είδη → τμήματα → sub.
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
  late SubCategoryDao dao;
  late int foodCategoryId;

  setUp(() async {
    db = inMemoryDb();
    dao = SubCategoryDao(db);
    foodCategoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
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
  Future<int> seedItem(int groupId, String name) =>
      ItemDao(db).insert(itemGroupId: groupId, name: name);

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

  group('SubCategoryDao.countItemsBySubCategoryId', () {
    test('κενή υποκατηγορία (με κενό τμήμα) → 0', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      await seedGroup(subId, 'Φέτα');

      expect(await dao.countItemsBySubCategoryId(subId), 0);
    });

    test('μετράει τα είδη όλων των τμημάτων της', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final group1 = await seedGroup(subId, 'Φέτα');
      final group2 = await seedGroup(subId, 'Γιαούρτια');
      await seedItem(group1, 'Γάλα');
      await seedItem(group2, 'Γιαούρτι');
      await seedItem(group2, 'Κεφίρ');

      expect(await dao.countItemsBySubCategoryId(subId), 3);
    });

    test('απομονώνει ξένη υποκατηγορία', () async {
      final dairyId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final bakeryId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Αρτοποιήματα',
      );
      final dairyGroup = await seedGroup(dairyId, 'Φέτα');
      final bakeryGroup = await seedGroup(bakeryId, 'Ψωμιά');
      await seedItem(dairyGroup, 'Γάλα');
      await seedItem(bakeryGroup, 'Ψωμί');

      expect(await dao.countItemsBySubCategoryId(dairyId), 1);
      expect(await dao.countItemsBySubCategoryId(bakeryId), 1);
    });
  });

  group('SubCategoryDao.countItemsInUseBySubCategoryId', () {
    test('είδη χωρίς γραμμές → 0', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final groupId = await seedGroup(subId, 'Φέτα');
      await seedItem(groupId, 'Γάλα');

      expect(await dao.countItemsInUseBySubCategoryId(subId), 0);
    });

    test('είδος με 2 γραμμές μετριέται μία φορά (DISTINCT)', () async {
      final seed = await seedUnitAndSupplier();
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
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

      expect(await dao.countItemsInUseBySubCategoryId(subId), 1);
    });

    test('απομονώνει ξένη υποκατηγορία', () async {
      final seed = await seedUnitAndSupplier();
      final dairyId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final bakeryId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Αρτοποιήματα',
      );
      final dairyGroup = await seedGroup(dairyId, 'Φέτα');
      final bakeryGroup = await seedGroup(bakeryId, 'Ψωμιά');
      final milkId = await seedItem(dairyGroup, 'Γάλα');
      await seedItem(bakeryGroup, 'Ψωμί');
      await seedReceiptLine(
        itemId: milkId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(await dao.countItemsInUseBySubCategoryId(dairyId), 1);
      expect(await dao.countItemsInUseBySubCategoryId(bakeryId), 0);
    });
  });

  group('SubCategoryDao.deleteWithContents', () {
    test('κενή υποκατηγορία → true και εξαφανίζεται', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'ΜΕΜΟΝΩΜΕΝΗ',
      );

      expect(await dao.deleteWithContents(subId), isTrue);
      expect(await dao.getById(subId), isNull);
    });

    test('με τμήματα+είδη χωρίς γραμμές → σβήνει τμήματα+είδη+υποκατηγορία',
        () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final groupDao = ItemGroupDao(db);
      final itemDao = ItemDao(db);
      final group1 = await seedGroup(subId, 'Φέτα');
      final group2 = await seedGroup(subId, 'Γιαούρτια');
      final milkId = await seedItem(group1, 'Γάλα');
      final yogurtId = await seedItem(group2, 'Γιαούρτι');

      expect(await dao.deleteWithContents(subId), isTrue);
      expect(await dao.getById(subId), isNull);
      expect(await groupDao.getById(group1), isNull);
      expect(await groupDao.getById(group2), isNull);
      expect(await itemDao.getById(milkId), isNull);
      expect(await itemDao.getById(yogurtId), isNull);
      // Η κατηγορία-γονέας παραμένει.
      expect(await CategoryDao(db).getById(foodCategoryId), isNotNull);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.deleteWithContents(9999), isFalse);
    });

    test('μπλοκαρισμένη (είδος με γραμμές) → throw + rollback', () async {
      final seed = await seedUnitAndSupplier();
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final groupDao = ItemGroupDao(db);
      final itemDao = ItemDao(db);
      final groupId = await seedGroup(subId, 'Φέτα');
      final milkId = await seedItem(groupId, 'Γάλα');
      final yogurtId = await seedItem(groupId, 'Γιαούρτι');
      await seedReceiptLine(
        itemId: milkId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      // RESTRICT: raw σφάλμα (ποτέ AppException) + πλήρες rollback.
      await expectLater(
        dao.deleteWithContents(subId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await dao.getById(subId), isNotNull);
      expect(await groupDao.getById(groupId), isNotNull);
      expect(await itemDao.getById(milkId), isNotNull);
      expect(await itemDao.getById(yogurtId), isNotNull);
      expect(await db.select(db.receiptLines).get(), hasLength(1));
    });
  });
}
