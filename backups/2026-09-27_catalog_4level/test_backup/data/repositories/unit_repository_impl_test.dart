/// Unit tests για το `UnitRepositoryImpl` (Φάση 2, Βήμα 2) — mapping.
///
/// CRUD + streams με `DataLoadException`. Ειδικά: FK RESTRICT στη διαγραφή
/// μονάδας που χρησιμοποιείται σε ΓΡΑΜΜΗ ΑΠΟΔΕΙΞΗΣ (ReceiptLines.unitId →
/// DataLoadException, διόρθωση docstring Βήμα 2) και SET NULL όταν είναι
/// μόνο προτεινόμενη μονάδα είδους (Items.defaultUnitId).
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
import 'package:times/data/repositories/unit_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double — raw σφάλμα στο watchAll για δοκιμή mapping.
class _FailingStreamUnitDao extends UnitDao {
  _FailingStreamUnitDao(super.db);

  @override
  Stream<List<Unit>> watchAll() =>
      Stream.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late dynamic db;
  late UnitRepositoryImpl repo;
  late CategoryDao categoryDao;
  late SubCategoryDao subDao;
  late ItemDao itemDao;
  late SupplierDao supplierDao;
  late ReceiptDao receiptDao;
  late ReceiptLineDao lineDao;

  setUp(() {
    db = inMemoryDb();
    repo = UnitRepositoryImpl(UnitDao(db));
    categoryDao = CategoryDao(db);
    subDao = SubCategoryDao(db);
    itemDao = ItemDao(db);
    supplierDao = SupplierDao(db);
    receiptDao = ReceiptDao(db);
    lineDao = ReceiptLineDao(db);
  });

  tearDown(() async => await db.close());

  group('UnitRepositoryImpl.insert/getById', () {
    test('insert + getById', () async {
      final id = await repo.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final row = await repo.getById(id);

      expect(row, isNotNull);
      expect(row!.name, 'Τεμάχιο');
      expect(row.abbreviation, 'τεμ');
      expect(row.allowsDecimal, isFalse);
    });

    test('allowsDecimal: true αποθηκεύεται', () async {
      final id = await repo.insert(
        name: 'Κιλό',
        abbreviation: 'kg',
        allowsDecimal: true,
      );
      expect((await repo.getById(id))!.allowsDecimal, isTrue);
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await repo.getById(999), isNull);
    });
  });

  group('UnitRepositoryImpl.watchAll', () {
    test('ordering: αλφαβητικά (name)', () async {
      final id2 = await repo.insert(name: 'Β', abbreviation: 'b');
      final id1 = await repo.insert(name: 'Α', abbreviation: 'a');
      final id3 = await repo.insert(name: 'Γ', abbreviation: 'c');

      final rows = await repo.watchAll().first;
      expect(rows.map((u) => u.id), [id1, id2, id3]);
    });
  });

  group('UnitRepositoryImpl.updateById/deleteById', () {
    test('updateById: name/abbreviation/allowsDecimal', () async {
      final id = await repo.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      expect(
        await repo.updateById(
          id,
          name: 'Μερίδα',
          abbreviation: 'με',
          allowsDecimal: true,
        ),
        isTrue,
      );
      final row = await repo.getById(id);
      expect(row!.name, 'Μερίδα');
      expect(row.abbreviation, 'με');
      expect(row.allowsDecimal, isTrue);
    });

    test('updateById ανύπαρκτο id → false', () async {
      expect(await repo.updateById(999, name: 'Χ'), isFalse);
    });

    test('deleteById ελεύθερης μονάδας → getById null', () async {
      final id = await repo.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      expect(await repo.deleteById(id), isTrue);
      expect(await repo.getById(id), isNull);
    });
  });

  group('UnitRepositoryImpl FK behavior (tables → units)', () {
    test('SET NULL: διαγραφή μονάδας που είναι item.defaultUnitId', () async {
      final unitId = await repo.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final categoryId = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId =
          await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final itemId =
          await itemDao.insert(subCategoryId: subId, name: 'Γάλα', defaultUnitId: unitId);

      expect(await repo.deleteById(unitId), isTrue);
      // SET NULL: το item μένει, χωρίς προτεινόμενη μονάδα.
      expect((await itemDao.getById(itemId))!.defaultUnitId, isNull);
    });

    test('RESTRICT: διαγραφή μονάδας σε ΓΡΑΜΜΗ ΑΠΟΔΕΙΞΗΣ → DataLoadException',
        () async {
      final unitId = await repo.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final categoryId = await categoryDao.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId =
          await subDao.insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final itemId = await itemDao.insert(subCategoryId: subId, name: 'Γάλα');
      final supplierId = await supplierDao.insert(name: 'Μάρκος');
      final receiptId =
          await receiptDao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      await lineDao.insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 1,
        priceCents: 199,
      );

      await expectLater(
        repo.deleteById(unitId),
        throwsA(isA<DataLoadException>()),
      );
      expect(await repo.getById(unitId), isNotNull);
    });
  });

  group('UnitRepositoryImpl stream mapping', () {
    test('raw stream σφάλμα → DataLoadException', () async {
      final failing = UnitRepositoryImpl(_FailingStreamUnitDao(db));
      await expectLater(
        failing.watchAll(),
        emitsError(isA<DataLoadException>()),
      );
    });
  });
}