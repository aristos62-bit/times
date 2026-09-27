/// Unit tests για το `ItemGroupRepositoryImpl` (27-09-2026) — mapping.
///
/// Mirror του `sub_category_repository_impl_test`: CRUD + streams
/// (watchAll, watchBySubCategoryId) με `DataLoadException` mapping —
/// FK RESTRICT (είδη σε τμήμα) στη διαγραφή + stream error + counts/cascade.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/repositories/item_group_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο watchBySubCategoryId για δοκιμή mapping.
class _FailingStreamItemGroupDao extends ItemGroupDao {
  _FailingStreamItemGroupDao(super.db);

  @override
  Stream<List<ItemGroup>> watchBySubCategoryId(int subCategoryId) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// DAO double που αποτυγχάνει στο count — έλεγχος mapping του
/// `countItemsInUse`. `Future.error` (όχι sync throw).
class _FailingCountItemGroupDao extends ItemGroupDao {
  _FailingCountItemGroupDao(super.db);

  @override
  Future<int> countItemsInUseByItemGroupId(int itemGroupId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// DAO double που αποτυγχάνει στα counts/cascade — mapping check Βήματος 4.
class _FailingCascadeItemGroupDao extends ItemGroupDao {
  _FailingCascadeItemGroupDao(super.db);

  @override
  Future<int> countItemsByItemGroupId(int itemGroupId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));

  @override
  Future<bool> deleteWithContents(int itemGroupId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late ItemGroupRepositoryImpl repo;
  late CategoryDao categoryDao;
  late SubCategoryDao subDao;
  late ItemDao itemDao;
  late int subCategoryId;
  late int categoryId;

  setUp(() async {
    db = inMemoryDb();
    repo = ItemGroupRepositoryImpl(ItemGroupDao(db));
    categoryDao = CategoryDao(db);
    subDao = SubCategoryDao(db);
    itemDao = ItemDao(db);

    categoryId = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
    subCategoryId =
        await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
  });

  tearDown(() async => await db.close());

  group('ItemGroupRepositoryImpl.insert/getById', () {
    test('insert + getById', () async {
      final id = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Φέτα',
      );
      final row = await repo.getById(id);

      expect(row, isNotNull);
      expect(row!.name, 'Φέτα');
      expect(row.subCategoryId, subCategoryId);
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await repo.getById(999), isNull);
    });
  });

  /// Αναζήτηση exact-match στο κανονικοποιημένο όνομα (soft dup-check
  /// §2.2 — UNIQUE `normalizedName`, §3).
  group('ItemGroupRepositoryImpl.getByNormalizedName', () {
    test('exact-match βρίσκει το τμήμα', () async {
      final id = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Φέτα',
      );
      final row = await repo.getByNormalizedName(
        GreekTextNormalizer.normalize('Φέτα'),
      );

      expect(row, isNotNull);
      expect(row!.id, id);
    });

    test('καμία αντιστοίχιση → null', () async {
      await repo.insert(subCategoryId: subCategoryId, name: 'Φέτα');
      expect(await repo.getByNormalizedName('ανυπαρκτο'), isNull);
    });
  });

  group('ItemGroupRepositoryImpl.watchAll / watchBySubCategoryId', () {
    test('watchAll: αλφαβητικά (name)', () async {
      await repo.insert(subCategoryId: subCategoryId, name: 'Γραβιέρα');
      await repo.insert(subCategoryId: subCategoryId, name: 'Φέτα');

      final rows = await repo.watchAll().first;
      expect(rows.map((g) => g.name), ['Γραβιέρα', 'Φέτα']);
    });

    test('watchBySubCategoryId: μόνο του ζητούμενου sub', () async {
      final otherSub = await subDao.insert(
        categoryId: categoryId,
        name: 'Κρέας',
      );
      await repo.insert(subCategoryId: subCategoryId, name: 'Φέτα');
      await repo.insert(subCategoryId: otherSub, name: 'Μπριζόλα');
      await repo.insert(subCategoryId: subCategoryId, name: 'Γραβιέρα');

      final rows = await repo.watchBySubCategoryId(subCategoryId).first;
      expect(rows.map((g) => g.name), ['Γραβιέρα', 'Φέτα']);
    });
  });

  group('ItemGroupRepositoryImpl.updateById', () {
    test('αλλάζει name αλλά και subCategoryId', () async {
      final otherSub = await subDao.insert(
        categoryId: categoryId,
        name: 'Κρέας',
      );
      final id = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Παλιό',
      );

      expect(
        await repo.updateById(id, name: 'Νέο', subCategoryId: otherSub),
        isTrue,
      );
      final row = await repo.getById(id);
      expect(row!.name, 'Νέο');
      expect(row.subCategoryId, otherSub);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await repo.updateById(999, name: 'Χ'), isFalse);
    });
  });

  group('ItemGroupRepositoryImpl.deleteById', () {
    test('διαγράφει χωρίς items → getById null', () async {
      final id = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Μόνο',
      );

      expect(await repo.deleteById(id), isTrue);
      expect(await repo.getById(id), isNull);
    });

    test('FK RESTRICT: με items → DataLoadException', () async {
      final id = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Με Items',
      );
      await itemDao.insert(itemGroupId: id, name: 'Γάλα');

      await expectLater(
        repo.deleteById(id),
        throwsA(isA<DataLoadException>()),
      );
      expect(await repo.getById(id), isNotNull);
    });
  });

  group('ItemGroupRepositoryImpl stream mapping', () {
    test('raw stream σφάλμα → DataLoadException', () async {
      final failing =
          ItemGroupRepositoryImpl(_FailingStreamItemGroupDao(db));
      await expectLater(
        failing.watchBySubCategoryId(1),
        emitsError(isA<DataLoadException>()),
      );
    });
  });

  group('ItemGroupRepositoryImpl.countItemsInUse', () {
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

    test('είδη χωρίς γραμμές → 0', () async {
      final groupId = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Φέτα',
      );
      await itemDao.insert(itemGroupId: groupId, name: 'Γάλα');

      expect(await repo.countItemsInUse(groupId), 0);
    });

    test('είδος με γραμμή → 1', () async {
      final seed = await seedUnitAndSupplier();
      final groupId = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Φέτα',
      );
      final itemId = await itemDao.insert(
        itemGroupId: groupId,
        name: 'Γάλα',
      );
      await seedReceiptLine(
        itemId: itemId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(await repo.countItemsInUse(groupId), 1);
    });

    test('ανύπαρκτο id → 0', () async {
      expect(await repo.countItemsInUse(999), 0);
    });

    test('raw σφάλμα DAO → DataLoadException (mapping)', () async {
      final failing =
          ItemGroupRepositoryImpl(_FailingCountItemGroupDao(db));
      await expectLater(
        failing.countItemsInUse(1),
        throwsA(isA<DataLoadException>()),
      );
    });
  });

  group('ItemGroupRepositoryImpl.countItems/deleteWithContents', () {
    test('countItems: 0 → N', () async {
      final groupId = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Φέτα',
      );
      expect(await repo.countItems(groupId), 0);
      await itemDao.insert(itemGroupId: groupId, name: 'Γάλα');
      expect(await repo.countItems(groupId), 1);
    });

    test('deleteWithContents καθαρού → true + σβησμένα είδη', () async {
      final groupId = await repo.insert(
        subCategoryId: subCategoryId,
        name: 'Φέτα',
      );
      final itemId = await itemDao.insert(
        itemGroupId: groupId,
        name: 'Γάλα',
      );

      expect(await repo.deleteWithContents(groupId), isTrue);
      expect(await repo.getById(groupId), isNull);
      expect(await itemDao.getById(itemId), isNull);
      // Η υποκατηγορία-γονέας μένει.
      expect(await subDao.getById(subCategoryId), isNotNull);
    });

    test('deleteWithContents ανύπαρκτου → false', () async {
      expect(await repo.deleteWithContents(999), isFalse);
    });

    test('σφάλμα DAO → DataLoadException (count + delete)', () async {
      final failing =
          ItemGroupRepositoryImpl(_FailingCascadeItemGroupDao(db));
      await expectLater(
        failing.countItems(1),
        throwsA(isA<DataLoadException>()),
      );
      await expectLater(
        failing.deleteWithContents(1),
        throwsA(isA<DataLoadException>()),
      );
    });
  });
}
