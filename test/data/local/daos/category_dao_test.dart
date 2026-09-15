/// Unit tests για το `CategoryDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// In-memory βάση (κοινό helper). Ελέγχει: insert/getById, watchAll
/// (ordering name), updateById, deleteById, πραγματική εγγραφή, και ότι
/// το FK RESTRICT αποτυγχάνει (raw) όταν υπάρχουν υποκατηγορίες.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late CategoryDao dao;

  setUp(() {
    db = inMemoryDb();
    dao = CategoryDao(db);
  });

  tearDown(() async => await db.close());

  group('CategoryDao.insert/getById', () {
    test('επιστρέφει id και η εγγραφή διαβάζεται', () async {
      final id = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      final row = await dao.getById(id);

      expect(row, isNotNull);
      expect(row!.name, 'ΤΡΟΦΙΜΑ');
    });

    test('getById ανύπαρκτο id → null', () async {
      expect(await dao.getById(999), isNull);
    });

    test('insert χωρίς εξαίρεση ρυθμίζει το createdAt', () async {
      final id = await dao.insert(name: 'ΟΙΚΙΑΚΑ');
      final row = await dao.getById(id);

      expect(row!.createdAt, isNotNull);
    });
  });

  group('CategoryDao.watchAll', () {
    test('αρχικά άδειο, μετά insert εμφανίζεται (real-time)', () async {
      expect(await dao.watchAll().first, isEmpty);

      await dao.insert(name: 'ΤΡΟΦΙΜΑ');

      final rows = await dao.watchAll().first;
      expect(rows.single.name, 'ΤΡΟΦΙΜΑ');
    });

    test('ordering: αλφαβητικά κατά name', () async {
      final id2 = await dao.insert(name: 'Β');
      final id1 = await dao.insert(name: 'Α');
      final id3 = await dao.insert(name: 'Γ');

      final rows = await dao.watchAll().first;
      expect(rows.map((c) => c.id), [id1, id2, id3]);
    });
  });

  group('CategoryDao.updateById', () {
    test('ενημερώνει το name', () async {
      final id = await dao.insert(name: 'ΠΑΛΙΟ');
      final ok = await dao.updateById(id, name: 'ΝΕΟ');

      expect(ok, isTrue);
      expect((await dao.getById(id))!.name, 'ΝΕΟ');
    });

    test('ανύπαρκτο id → false (0 rows affected)', () async {
      expect(await dao.updateById(999, name: 'Χ'), isFalse);
    });
  });

  group('CategoryDao.deleteById', () {
    test('διαγράφει και getById → null', () async {
      final id = await dao.insert(name: 'ΠΡΟΣ ΔΙΑΓΡΑΦΗ');
      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.deleteById(999), isFalse);
    });
  });

  group('FK RESTRICT (tables → categories)', () {
    test('αποτυγχάνει raw (όχι AppException) αν υπάρχουν υποκατηγορίες',
        () async {
      final categoryId = await dao.insert(name: 'ΤΡΟΦΙΜΑ');
      await SubCategoryDao(db).insert(categoryId: categoryId, name: 'Γαλακτοκομικά');

      // RESTRICT: η διαγραφή ρίχνει raw constraint error (SqliteException) —
      // ποτέ DataLoadException: το mapping γίνεται στο Repository (Φάση 2).
      await expectLater(
        dao.deleteById(categoryId),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      // …και η κατηγορία παραμένει (atomicity).
      expect(await dao.getById(categoryId), isNotNull);
    });
  });
}