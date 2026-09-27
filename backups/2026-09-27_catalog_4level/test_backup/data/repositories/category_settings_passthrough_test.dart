/// Unit tests — repo passthrough Βήματος 4 (§2.3 DESIGN / Φάση 4 Βήμα 4).
///
/// `countItems` (σύνολο — cascade confirm) + `deleteWithContents` (cascade
/// σε transaction) για Category/SubCategory: τιμές + error mapping σε
/// `DataLoadException` (ποτέ raw SqliteException). In-memory βάση
/// (pattern `category_repository_impl_test`).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/app_database.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/repositories/category_repository_impl.dart';
import 'package:times/data/repositories/sub_category_repository_impl.dart';

import '../local/helpers/in_memory_db.dart';

/// DAO double που αποτυγχάνει στα Βήματος-4 counts/cascade — mapping check.
class _FailingCascadeCategoryDao extends CategoryDao {
  _FailingCascadeCategoryDao(super.db);

  @override
  Future<int> countItemsByCategoryId(int categoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));

  @override
  Future<bool> deleteWithContents(int categoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

class _FailingCascadeSubCategoryDao extends SubCategoryDao {
  _FailingCascadeSubCategoryDao(super.db);

  @override
  Future<int> countItemsBySubCategoryId(int subCategoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));

  @override
  Future<bool> deleteWithContents(int subCategoryId) =>
      Future.error(SqliteException(extendedResultCode: 1, message: 'test'));
}

void main() {
  late AppDatabase db;
  late CategoryRepositoryImpl catRepo;
  late SubCategoryRepositoryImpl subRepo;
  late ItemDao itemDao;

  setUp(() {
    db = inMemoryDb();
    catRepo = CategoryRepositoryImpl(CategoryDao(db));
    subRepo = SubCategoryRepositoryImpl(SubCategoryDao(db));
    itemDao = ItemDao(db);
  });

  tearDown(() async => await db.close());

  group('CategoryRepository.countItems/deleteWithContents (Βήμα 4)', () {
    test('countItems: 0 → N (σύνολο, όχι DISTINCT)', () async {
      final catId = await catRepo.insert(name: 'ΤΡΟΦΙΜΑ');
      expect(await catRepo.countItems(catId), 0);
      final subId = await subRepo.insert(
        categoryId: catId,
        name: 'Γαλακτοκομικά',
      );
      await itemDao.insert(subCategoryId: subId, name: 'Γάλα');
      await itemDao.insert(subCategoryId: subId, name: 'Τυρί');
      expect(await catRepo.countItems(catId), 2);
    });

    test('deleteWithContents καθαρής → true + άδειο δέντρο', () async {
      final catId = await catRepo.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await subRepo.insert(
        categoryId: catId,
        name: 'Γαλακτοκομικά',
      );
      await itemDao.insert(subCategoryId: subId, name: 'Γάλα');

      expect(await catRepo.deleteWithContents(catId), isTrue);
      expect(await catRepo.getById(catId), isNull);
      expect(await subRepo.getById(subId), isNull);
    });

    test('deleteWithContents ανύπαρκτου → false', () async {
      expect(await catRepo.deleteWithContents(999), isFalse);
    });

    test('σφάλμα DAO → DataLoadException (count + delete)', () async {
      final failing = CategoryRepositoryImpl(_FailingCascadeCategoryDao(db));
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

  group('SubCategoryRepository.countItems/deleteWithContents (Βήμα 4)', () {
    test('countItems: 0 → N', () async {
      final catId = await catRepo.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await subRepo.insert(
        categoryId: catId,
        name: 'Γαλακτοκομικά',
      );
      expect(await subRepo.countItems(subId), 0);
      await itemDao.insert(subCategoryId: subId, name: 'Γάλα');
      expect(await subRepo.countItems(subId), 1);
    });

    test('deleteWithContents καθαρής → true + σβησμένα είδη', () async {
      final catId = await catRepo.insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await subRepo.insert(
        categoryId: catId,
        name: 'Γαλακτοκομικά',
      );
      final itemId = await itemDao.insert(
        subCategoryId: subId,
        name: 'Γάλα',
      );

      expect(await subRepo.deleteWithContents(subId), isTrue);
      expect(await subRepo.getById(subId), isNull);
      expect(await itemDao.getById(itemId), isNull);
      // Η κατηγορία-γονέας μένει.
      expect(await catRepo.getById(catId), isNotNull);
    });

    test('deleteWithContents ανύπαρκτου → false', () async {
      expect(await subRepo.deleteWithContents(999), isFalse);
    });

    test('σφάλμα DAO → DataLoadException (count + delete)', () async {
      final failing = SubCategoryRepositoryImpl(
        _FailingCascadeSubCategoryDao(db),
      );
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
