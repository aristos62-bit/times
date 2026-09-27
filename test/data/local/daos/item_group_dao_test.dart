/// Unit tests για το `ItemGroupDao` (Τμήματα — Refactor 4 επιπέδων
/// 27-09-2026) — CRUD + streams + normalizedName + counts + cascade.
///
/// Mirror του `sub_category_dao_test`: insert/getById, watchAll +
/// watchBySubCategoryId (ordering, filter), SPoT `normalizedName`
/// (insert-time + re-calc στο updateById + getByNormalizedName + UNIQUE raw),
/// updateById (μερική ενημέρωση), deleteById, FK: insert raw error όταν το
/// subCategoryId δεν υπάρχει + RESTRICT όταν υπάρχουν είδη· πάντα raw (όχι
/// AppException) — mapping στο Repository. Plus: counts 1 join
/// (group→item) + `deleteWithContents` (είδη → τμήμα, 1 transaction).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
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
  late ItemGroupDao dao;
  late int foodCategoryId;
  late int dairySubId;

  /// Φτιάχνει την αλυσίδα ΤΡΟΦΙΜΑ → Γαλακτοκομικά (χωρίς τμήματα/είδη).
  setUp(() async {
    db = inMemoryDb();
    dao = ItemGroupDao(db);
    foodCategoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    dairySubId = await SubCategoryDao(db)
        .insert(categoryId: foodCategoryId, name: 'Γαλακτοκομικά');
  });

  /// Κλείνει την in-memory βάση μετά από κάθε test.
  tearDown(() async => await db.close());

  /// Δημιουργεί μονάδα + προμηθευτή (απαραίτητα για γραμμές απόδειξης).
  Future<({int unitId, int supplierId})> seedUnitAndSupplier() async {
    final unitId =
        await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    return (unitId: unitId, supplierId: supplierId);
  }

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

  group('ItemGroupDao.insert/getById', () {
    test('επιστρέφει id και η εγγραφή διαβάζεται', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final row = await dao.getById(id);

      expect(row, isNotNull);
      expect(row!.subCategoryId, dairySubId);
      expect(row.name, 'Φέτα');
    });

    test('FK: ανύπαρκτο subCategoryId → raw error (όχι AppException)',
        () async {
      await expectLater(
        dao.insert(subCategoryId: 9999, name: 'Ορφανό'),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('ItemGroupDao.insert (SPoT normalizedName)', () {
    test('μετά τόνο/πεζά: «Φέτα» → «φετα»', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final row = await dao.getById(id);

      expect(row!.name, 'Φέτα');
      expect(row.normalizedName, 'φετα');
    });

    test('normalize == GreekTextNormalizer.normalize (SPoT §3)', () async {
      const name = 'Έξτρα Φέτα Βαρελιού';
      final id = await dao.insert(subCategoryId: dairySubId, name: name);
      final row = await dao.getById(id);

      expect(row!.normalizedName, GreekTextNormalizer.normalize(name));
    });

    test('UNIQUE duplicate raw error: «Φέτα» vs «ΦΕΤΑ»', () async {
      await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');

      await expectLater(
        dao.insert(subCategoryId: dairySubId, name: 'ΦΕΤΑ'),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      // …και μόνο μία εγγραφή τελικά (atomicity του constraint).
      final all = await dao.watchAll().first;
      expect(all.length, 1);
    });
  });

  group('ItemGroupDao.getByNormalizedName', () {
    test('βρίσκει με ακριβές normalizedName', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final row = await dao.getByNormalizedName('φετα');

      expect(row, isNotNull);
      expect(row!.id, id);
    });

    test('ανύπαρκτο → null (όχι exception)', () async {
      expect(await dao.getByNormalizedName('ανύπαρκτο'), isNull);
    });
  });

  group('ItemGroupDao.watchAll', () {
    test('αρχικά άδειο, μετά insert εμφανίζεται (real-time)', () async {
      expect(await dao.watchAll().first, isEmpty);

      final id = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final rows = await dao.watchAll().first;

      expect(rows.map((g) => g.id), [id]);
    });

    test('ordering: αλφαβητικά κατά name', () async {
      final idB = await dao.insert(subCategoryId: dairySubId, name: 'Β');
      final idA = await dao.insert(subCategoryId: dairySubId, name: 'Α');
      final idC = await dao.insert(subCategoryId: dairySubId, name: 'Γ');

      final rows = await dao.watchAll().first;
      expect(rows.map((g) => g.id), [idA, idB, idC]);
    });
  });

  group('ItemGroupDao.watchBySubCategoryId', () {
    test('φιλτράρει μόνο τη ζητούμενη υποκατηγορία', () async {
      final otherSubId = await SubCategoryDao(db)
          .insert(categoryId: foodCategoryId, name: 'Αρτοποιήματα');
      await dao.insert(subCategoryId: otherSubId, name: 'ΞΕΝΟ');
      await dao.insert(subCategoryId: dairySubId, name: 'Α');
      await dao.insert(subCategoryId: dairySubId, name: 'Β');

      final rows = await dao.watchBySubCategoryId(dairySubId).first;
      expect(rows.map((g) => g.name), ['Α', 'Β']);
    });
  });

  group('ItemGroupDao.updateById', () {
    test('μερική ενημέρωση: μόνο name ή μόνο subCategoryId', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'ΠΑΛΙΟ');
      final otherSubId = await SubCategoryDao(db)
          .insert(categoryId: foodCategoryId, name: 'Αρτοποιήματα');

      expect(await dao.updateById(id, name: 'ΝΕΟ'), isTrue);
      expect((await dao.getById(id))!.name, 'ΝΕΟ');

      expect(await dao.updateById(id, subCategoryId: otherSubId), isTrue);
      expect((await dao.getById(id))!.subCategoryId, otherSubId);
    });

    test('αλλαγή name → ξανά-υπολογισμός normalizedName (SPoT §3)', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      expect(await dao.updateById(id, name: 'ΦΕΤΑ ΒΑΡΕΛΙΟΥ'), isTrue);

      final row = await dao.getById(id);
      expect(row!.name, 'ΦΕΤΑ ΒΑΡΕΛΙΟΥ');
      expect(
        row.normalizedName,
        GreekTextNormalizer.normalize('ΦΕΤΑ ΒΑΡΕΛΙΟΥ'),
      );
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.updateById(9999, name: 'Χ'), isFalse);
    });
  });

  group('ItemGroupDao.deleteById', () {
    test('διαγράφει χωρίς εξαρτήσεις', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'ΜΕΜΟΝΩΜΕΝΟ');
      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });

    test('RESTRICT: raw error αν υπάρχουν είδη', () async {
      final groupId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      // Το είδος (χωρίς defaultUnitId) αρκεί για το RESTRICT.
      await seedItem(groupId, 'Γάλα');

      await expectLater(
        dao.deleteById(groupId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await dao.getById(groupId), isNotNull);
    });
  });

  group('ItemGroupDao.countItemsByItemGroupId', () {
    test('κενό τμήμα → 0', () async {
      final groupId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');

      expect(await dao.countItemsByItemGroupId(groupId), 0);
    });

    test('μετράει τα είδη του', () async {
      final groupId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      await seedItem(groupId, 'Γάλα');
      await seedItem(groupId, 'Φέτα βαρελιού');

      expect(await dao.countItemsByItemGroupId(groupId), 2);
    });

    test('απομονώνει ξένο τμήμα', () async {
      final fetaId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final yogurtId =
          await dao.insert(subCategoryId: dairySubId, name: 'Γιαούρτια');
      await seedItem(fetaId, 'Γάλα');
      await seedItem(yogurtId, 'Γιαούρτι');

      expect(await dao.countItemsByItemGroupId(fetaId), 1);
      expect(await dao.countItemsByItemGroupId(yogurtId), 1);
    });
  });

  group('ItemGroupDao.countItemsInUseByItemGroupId', () {
    test('είδη χωρίς γραμμές → 0', () async {
      final groupId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      await seedItem(groupId, 'Γάλα');

      expect(await dao.countItemsInUseByItemGroupId(groupId), 0);
    });

    test('είδος με 2 γραμμές μετριέται μία φορά (DISTINCT)', () async {
      final seed = await seedUnitAndSupplier();
      final groupId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
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

      expect(await dao.countItemsInUseByItemGroupId(groupId), 1);
    });

    test('απομονώνει ξένο τμήμα', () async {
      final seed = await seedUnitAndSupplier();
      final fetaId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final yogurtId =
          await dao.insert(subCategoryId: dairySubId, name: 'Γιαούρτια');
      final milkId = await seedItem(fetaId, 'Γάλα');
      await seedItem(yogurtId, 'Γιαούρτι');
      await seedReceiptLine(
        itemId: milkId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(await dao.countItemsInUseByItemGroupId(fetaId), 1);
      expect(await dao.countItemsInUseByItemGroupId(yogurtId), 0);
    });
  });

  group('ItemGroupDao.deleteWithContents', () {
    test('κενό τμήμα → true και εξαφανίζεται', () async {
      final groupId =
          await dao.insert(subCategoryId: dairySubId, name: 'ΜΕΜΟΝΩΜΕΝΟ');

      expect(await dao.deleteWithContents(groupId), isTrue);
      expect(await dao.getById(groupId), isNull);
    });

    test('με είδη χωρίς γραμμές → σβήνει είδη+τμήμα', () async {
      final groupId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final itemDao = ItemDao(db);
      final milkId = await seedItem(groupId, 'Γάλα');
      final barrelId = await seedItem(groupId, 'Φέτα βαρελιού');

      expect(await dao.deleteWithContents(groupId), isTrue);
      expect(await dao.getById(groupId), isNull);
      expect(await itemDao.getById(milkId), isNull);
      expect(await itemDao.getById(barrelId), isNull);
      // Η υποκατηγορία-γονέας παραμένει.
      expect(await SubCategoryDao(db).getById(dairySubId), isNotNull);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.deleteWithContents(9999), isFalse);
    });

    test('μπλοκαρισμένο (είδος με γραμμές) → throw + rollback', () async {
      final seed = await seedUnitAndSupplier();
      final groupId = await dao.insert(subCategoryId: dairySubId, name: 'Φέτα');
      final itemDao = ItemDao(db);
      final milkId = await seedItem(groupId, 'Γάλα');
      final barrelId = await seedItem(groupId, 'Φέτα βαρελιού');
      await seedReceiptLine(
        itemId: milkId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      // RESTRICT: raw σφάλμα (ποτέ AppException) + πλήρες rollback.
      await expectLater(
        dao.deleteWithContents(groupId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await dao.getById(groupId), isNotNull);
      expect(await itemDao.getById(milkId), isNotNull);
      expect(await itemDao.getById(barrelId), isNotNull);
      expect(await db.select(db.receiptLines).get(), hasLength(1));
    });
  });
}
