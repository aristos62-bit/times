/// Unit tests για το `SubCategoryRepositoryImpl` (Φάση 2, Βήμα 2) — mapping.
///
/// CRUD + streams (watchAll, watchByCategoryId) με `DataLoadException`
/// mapping: FK RESTRICT (items σε υποκατηγορία) στη διαγραφή + stream error
/// μετά από close.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/repositories/sub_category_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο watchByCategoryId για δοκιμή mapping.
class _FailingStreamSubCategoryDao extends SubCategoryDao {
  _FailingStreamSubCategoryDao(super.db);

  @override
  Stream<List<SubCategory>> watchByCategoryId(int categoryId) =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

/// DAO double που αποτυγχάνει στο count — ντετερμινιστικός έλεγχος mapping
/// του `countItemsInUse` (Βήμα 3). `Future.error` (όχι sync throw).
class _FailingCountSubCategoryDao extends SubCategoryDao {
  _FailingCountSubCategoryDao(super.db);

  @override
  Future<int> countItemsInUseBySubCategoryId(int subCategoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late SubCategoryRepositoryImpl repo;
  late CategoryDao categoryDao;
  late ItemDao itemDao;

  setUp(() {
    db = inMemoryDb();
    repo = SubCategoryRepositoryImpl(SubCategoryDao(db));
    categoryDao = CategoryDao(db);
    itemDao = ItemDao(db);
  });

  tearDown(() async => await db.close());

  group('SubCategoryRepositoryImpl.insert/getById', () {
    test('insert + getById', () async {
      final categoryId = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
      final id = await repo.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final row = await repo.getById(id);

      expect(row, isNotNull);
      expect(row!.name, 'Γαλακτοκομικά');
      expect(row.categoryId, categoryId);
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await repo.getById(999), isNull);
    });
  });

  group('SubCategoryRepositoryImpl.watchAll / watchByCategoryId', () {
    test('watchAll: αλφαβητικά (name), όλα τα categories', () async {
      final c1 = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
      final c2 = await categoryDao.insert(name: 'ΟΙΚΙΑΚΑ');
      await repo.insert(categoryId: c2, name: 'Καθαριστικά');
      await repo.insert(categoryId: c1, name: 'Γαλακτοκομικά');

      final rows = await repo.watchAll().first;
      expect(rows.map((s) => s.name), ['Γαλακτοκομικά', 'Καθαριστικά']);
    });

    test('watchByCategoryId: μόνο της ζητούμενης κατηγορίας', () async {
      final c1 = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
      final c2 = await categoryDao.insert(name: 'ΟΙΚΙΑΚΑ');
      await repo.insert(categoryId: c1, name: 'Γαλακτοκομικά');
      await repo.insert(categoryId: c2, name: 'Καθαριστικά');
      await repo.insert(categoryId: c1, name: 'Κρέας');

      final rows = await repo.watchByCategoryId(c1).first;
      expect(rows.map((s) => s.name), ['Γαλακτοκομικά', 'Κρέας']);
    });
  });

  group('SubCategoryRepositoryImpl.updateById', () {
    test('αλλάζει name αλλά και categoryId', () async {
      final c1 = await categoryDao.insert(name: 'Α');
      final c2 = await categoryDao.insert(name: 'Β');
      final id = await repo.insert(categoryId: c1, name: 'Παλιό');

      expect(await repo.updateById(id, name: 'Νέο', categoryId: c2), isTrue);
      final row = await repo.getById(id);
      expect(row!.name, 'Νέο');
      expect(row.categoryId, c2);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await repo.updateById(999, name: 'Χ'), isFalse);
    });
  });

  group('SubCategoryRepositoryImpl.deleteById', () {
    test('διαγράφει χωρίς items → getById null', () async {
      final categoryId = await categoryDao.insert(name: 'Α');
      final id = await repo.insert(categoryId: categoryId, name: 'Μόνη');

      expect(await repo.deleteById(id), isTrue);
      expect(await repo.getById(id), isNull);
    });

    test('FK RESTRICT: με items → DataLoadException', () async {
      final categoryId = await categoryDao.insert(name: 'Α');
      final id =
          await repo.insert(categoryId: categoryId, name: 'Με Items');
      await itemDao.insert(subCategoryId: id, name: 'Γάλα');

      await expectLater(
        repo.deleteById(id),
        throwsA(isA<DataLoadException>()),
      );
      expect(await repo.getById(id), isNotNull);
    });
  });

  group('SubCategoryRepositoryImpl stream mapping', () {
    test('raw stream σφάλμα → DataLoadException', () async {
      final failing =
          SubCategoryRepositoryImpl(_FailingStreamSubCategoryDao(db));
      await expectLater(
        failing.watchByCategoryId(1),
        emitsError(isA<DataLoadException>()),
      );
    });
  });

  group('SubCategoryRepositoryImpl.countItemsInUse (Βήμα 3)', () {
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

    Future<({int subId, int itemId})> seedSubWithMilk(String name) async {
      final categoryId = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ $name');
      final subId = await repo.insert(categoryId: categoryId, name: name);
      final itemId =
          await itemDao.insert(subCategoryId: subId, name: 'Γάλα $name');
      return (subId: subId, itemId: itemId);
    }

    test('είδη χωρίς γραμμές → 0', () async {
      final seed = await seedSubWithMilk('Γαλακτοκομικά');

      expect(await repo.countItemsInUse(seed.subId), 0);
    });

    test('είδος με γραμμή → 1', () async {
      final seed = await seedUnitAndSupplier();
      final sub = await seedSubWithMilk('Γαλακτοκομικά');
      await seedReceiptLine(
        itemId: sub.itemId,
        unitId: seed.unitId,
        supplierId: seed.supplierId,
      );

      expect(await repo.countItemsInUse(sub.subId), 1);
    });

    test('ανύπαρκτο id → 0', () async {
      expect(await repo.countItemsInUse(999), 0);
    });

    test('raw σφάλμα DAO → DataLoadException (mapping)', () async {
      final failing =
          SubCategoryRepositoryImpl(_FailingCountSubCategoryDao(db));
      await expectLater(
        failing.countItemsInUse(1),
        throwsA(isA<DataLoadException>()),
      );
    });
  });
}