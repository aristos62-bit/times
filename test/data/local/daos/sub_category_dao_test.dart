/// Unit tests για το `SubCategoryDao` (Refactor 4 επιπέδων 27-09-2026) —
/// CRUD + streams + normalizedName.
///
/// Ελέγχει insert/getById, watchAll + watchByCategoryId (ordering, filter),
/// SPoT `normalizedName` (mirror `ItemDao`: insert-time + re-calc στο
/// updateById + getByNormalizedName + UNIQUE raw), updateById (μερική
/// ενημέρωση), deleteById, FK: insert raw error όταν το categoryId δεν
/// υπάρχει + RESTRICT όταν υπάρχουν τμήματα· πάντα raw (όχι AppException)
/// — mapping στο Repository.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_group_dao.dart';
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

  group('SubCategoryDao.insert (SPoT normalizedName)', () {
    test('μετά τόνο/πεζά: «Γαλακτοκομικά» → «γαλακτοκομικα»', () async {
      final id = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final row = await dao.getById(id);

      expect(row!.name, 'Γαλακτοκομικά');
      expect(row.normalizedName, 'γαλακτοκομικα');
    });

    test('normalize == GreekTextNormalizer.normalize (SPoT §3)', () async {
      const name = 'Έξτρα Γαλακτοκομικά';
      final id = await dao.insert(categoryId: foodCategoryId, name: name);
      final row = await dao.getById(id);

      expect(row!.normalizedName, GreekTextNormalizer.normalize(name));
    });

    test('UNIQUE duplicate raw error: «Γαλακτοκομικά» vs «ΓΑΛΑΚΤΟΚΟΜΙΚΑ»',
        () async {
      await dao.insert(categoryId: foodCategoryId, name: 'Γαλακτοκομικά');

      await expectLater(
        dao.insert(categoryId: foodCategoryId, name: 'ΓΑΛΑΚΤΟΚΟΜΙΚΑ'),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      // …και μόνο μία εγγραφή τελικά (atomicity του constraint).
      final all = await dao.watchAll().first;
      expect(all.length, 1);
    });
  });

  group('SubCategoryDao.getByNormalizedName', () {
    test('βρίσκει με ακριβές normalizedName', () async {
      final id = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      final row = await dao.getByNormalizedName('γαλακτοκομικα');

      expect(row, isNotNull);
      expect(row!.id, id);
    });

    test('ανύπαρκτο → null (όχι exception)', () async {
      expect(await dao.getByNormalizedName('ανύπαρκτο'), isNull);
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

    test('αλλαγή name → ξανά-υπολογισμός normalizedName (SPoT §3)', () async {
      final id = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      expect(await dao.updateById(id, name: 'ΑΡΤΟΠΟΙΗΜΑΤΑ'), isTrue);

      final row = await dao.getById(id);
      expect(row!.name, 'ΑΡΤΟΠΟΙΗΜΑΤΑ');
      expect(
        row.normalizedName,
        GreekTextNormalizer.normalize('ΑΡΤΟΠΟΙΗΜΑΤΑ'),
      );
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

    test('RESTRICT: raw error αν υπάρχουν τμήματα (4 επίπεδα)', () async {
      final subId = await dao.insert(
        categoryId: foodCategoryId,
        name: 'Γαλακτοκομικά',
      );
      // Το τμήμα (χωρίς είδη) αρκεί για να ενεργοποιηθεί το RESTRICT.
      await ItemGroupDao(db).insert(subCategoryId: subId, name: 'Φέτα');

      await expectLater(
        dao.deleteById(subId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await dao.getById(subId), isNotNull);
    });
  });
}
