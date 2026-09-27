/// Unit tests για το `SubCategoryDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// Ελέγχει insert/getById, watchAll + watchByCategoryId (ordering, filter),
/// updateById (μερική ενημέρωση), deleteById, FK: insert raw error όταν το
/// categoryId δεν υπάρχει + RESTRICT όταν υπάρχουν items· πάντα raw (όχι
/// AppException) — mapping στο Repository (Φάση 2).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';

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

  group('SubCategoryDao.insert/getById', () {
    test('επιστρέφει id και η εγγραφή διαβάζεται', () async {
      final id = await dao.insert(categoryId: foodCategoryId, name: 'Γαλακτοκομικά');
      final row = await dao.getById(id);

      expect(row, isNotNull);
      expect(row!.categoryId, foodCategoryId);
      expect(row.name, 'Γαλακτοκομικά');
    });

    test('FK: ανύπαρκτο categoryId → raw error (όχι AppException)', () async {
      await expectLater(
        dao.insert(categoryId: 9999, name: 'Ορφανό'),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('SubCategoryDao.watchAll', () {
    test('αρχικά άδειο, μετά insert εμφανίζεται (real-time)', () async {
      expect(await dao.watchAll().first, isEmpty);

      final id = await dao.insert(categoryId: foodCategoryId, name: 'Α');
      final rows = await dao.watchAll().first;

      expect(rows.map((s) => s.id), [id]);
    });

    test('ordering: αλφαβητικά κατά name', () async {
      final idB = await dao.insert(categoryId: foodCategoryId, name: 'Β');
      final idA = await dao.insert(categoryId: foodCategoryId, name: 'Α');
      final idC = await dao.insert(categoryId: foodCategoryId, name: 'Γ');

      final rows = await dao.watchAll().first;
      expect(rows.map((s) => s.id), [idA, idB, idC]);
    });
  });

  group('SubCategoryDao.watchByCategoryId', () {
    test('φιλτράρει μόνο τη ζητούμενη κατηγορία', () async {
      final otherId = await CategoryDao(db).insert(name: 'ΟΙΚΙΑΚΑ');
      await dao.insert(categoryId: otherId, name: 'ΞΕΝΟ');
      await dao.insert(categoryId: foodCategoryId, name: 'Α');
      await dao.insert(categoryId: foodCategoryId, name: 'Β');

      final rows = await dao.watchByCategoryId(foodCategoryId).first;
      expect(rows.map((s) => s.name), ['Α', 'Β']);
    });
  });

  group('SubCategoryDao.updateById', () {
    test('μερική ενημέρωση: μόνο name ή μόνο categoryId', () async {
      final id = await dao.insert(categoryId: foodCategoryId, name: 'ΠΑΛΙΟ');
      final otherId = await CategoryDao(db).insert(name: 'ΟΙΚΙΑΚΑ');

      expect(await dao.updateById(id, name: 'ΝΕΟ'), isTrue);
      expect((await dao.getById(id))!.name, 'ΝΕΟ');

      expect(await dao.updateById(id, categoryId: otherId), isTrue);
      expect((await dao.getById(id))!.categoryId, otherId);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.updateById(9999, name: 'Χ'), isFalse);
    });
  });

  group('SubCategoryDao.deleteById', () {
    test('διαγράφει χωρίς εξαρτήσεις', () async {
      final id = await dao.insert(categoryId: foodCategoryId, name: 'ΜΕΜΟΝΩΜΕΝΗ');
      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });

    test('RESTRICT: raw error αν υπάρχουν items', () async {
      final subId = await dao.insert(categoryId: foodCategoryId, name: 'Γαλακτοκομικά');
      // Το Item (χωρίς defaultUnitId) αρκεί για να ενεργοποιηθεί το RESTRICT.
      await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');

      await expectLater(
        dao.deleteById(subId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await dao.getById(subId), isNotNull);
    });
  });
}