/// Unit tests για τα counts + cascade του `SubCategoryDao`
/// (Φάση 4, Βήμα 2 · §2.3).
///
/// In-memory βάση (κοινό helper). Ελέγχει: `countItemsBySubCategoryId`
/// (0/N + απομόνωση ξένης υποκατηγορίας), `countItemsInUseBySubCategoryId`
/// (0/DISTINCT + απομόνωση), `deleteWithContents` (κενή/με είδη/ανύπαρκτη +
/// ατομικότητα σε μπλοκαρισμένη). Τα σφάλματα FK είναι raw
/// (όχι AppException) — mapping στο Repository (Βήμα 3).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
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
    test('κενή υποκατηγορία → 0', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );

      expect(await dao.countItemsBySubCategoryId(subId), 0);
    });

    test('μετράει τα είδη της', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final itemDao = ItemDao(db);
      await itemDao.insert(subCategoryId: subId, name: 'Γάλα');
      await itemDao.insert(subCategoryId: subId, name: 'Γιαούρτι');

      expect(await dao.countItemsBySubCategoryId(subId), 2);
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
      final itemDao = ItemDao(db);
      await itemDao.insert(subCategoryId: dairyId, name: 'Γάλα');
      await itemDao.insert(subCategoryId: bakeryId, name: 'Ψωμί');

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
      await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');

      expect(await dao.countItemsInUseBySubCategoryId(subId), 0);
    });

    test('είδος με 2 γραμμές μετριέται μία φορά (DISTINCT)', () async {
      final seed = await seedUnitAndSupplier();
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final itemId =
          await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
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
      final itemDao = ItemDao(db);
      final milkId =
          await itemDao.insert(subCategoryId: dairyId, name: 'Γάλα');
      await itemDao.insert(subCategoryId: bakeryId, name: 'Ψωμί');
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

    test('με είδη χωρίς γραμμές → σβήνει είδη+υποκατηγορία', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final itemDao = ItemDao(db);
      final milkId =
          await itemDao.insert(subCategoryId: subId, name: 'Γάλα');
      final yogurtId =
          await itemDao.insert(subCategoryId: subId, name: 'Γιαούρτι');

      expect(await dao.deleteWithContents(subId), isTrue);
      expect(await dao.getById(subId), isNull);
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
      final itemDao = ItemDao(db);
      final milkId =
          await itemDao.insert(subCategoryId: subId, name: 'Γάλα');
      final yogurtId =
          await itemDao.insert(subCategoryId: subId, name: 'Γιαούρτι');
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
      expect(await itemDao.getById(milkId), isNotNull);
      expect(await itemDao.getById(yogurtId), isNotNull);
      expect(await db.select(db.receiptLines).get(), hasLength(1));
    });
  });
}
