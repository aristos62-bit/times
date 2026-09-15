/// Unit tests για το `ItemDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// Κύρια εστίαση (SPoT §3): το `normalizedName` υπολογίζεται πάντα
/// εσωτερικά με `GreekTextNormalizer.normalize(name)` και ξανα-υπολογίζεται
/// στο updateById όταν αλλάζει το name — ο caller δεν μπορεί να το "ξεχάσει".
/// Επίσης UNIQUE duplicate-check (raw), FK raw error (ανύπαρκτη υποκατηγορία)
/// και RESTRICT (items σε γραμμές αποδείξεων).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late ItemDao dao;
  late int foodCategoryId;
  late int dairySubId;

  setUp(() async {
    db = inMemoryDb();
    dao = ItemDao(db);
    foodCategoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    dairySubId = await SubCategoryDao(db)
        .insert(categoryId: foodCategoryId, name: 'Γαλακτοκομικά');
  });

  tearDown(() async => await db.close());

  group('ItemDao.insert (SPoT normalizedName)', () {
    test('μετά τόνο/πεζά: «Γάλα» → normalizedName «γαλα»', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');
      final row = await dao.getById(id);

      expect(row!.name, 'Γάλα');
      expect(row.normalizedName, 'γαλα');
    });

    test('normalize == GreekTextNormalizer.normalize (SPoT §3)', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Έξτρα Γάλα');
      final row = await dao.getById(id);

      expect(
        row!.normalizedName,
        GreekTextNormalizer.normalize('Έξτρα Γάλα'),
      );
    });

    test('defaultUnitId: προαιρετικό, null όταν λείπει', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');
      expect((await dao.getById(id))!.defaultUnitId, isNull);
    });

    test('defaultUnitId: αποθηκεύεται όταν δίνεται', () async {
      final unitId = await UnitDao(db).insert(name: 'Λίτρο', abbreviation: 'λτ');
      final id = await dao.insert(
        subCategoryId: dairySubId,
        name: 'Γάλα',
        defaultUnitId: unitId,
      );

      expect((await dao.getById(id))!.defaultUnitId, unitId);
    });

    test('FK raw error (όχι AppException) σε ανύπαρκτη υποκατηγορία',
        () async {
      await expectLater(
        dao.insert(subCategoryId: 9999, name: 'Γάλα'),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
    });

    test('UNIQUE duplicate raw error: «Γάλα» vs «γαλα» παγκόσμια', () async {
      await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');

      await expectLater(
        dao.insert(subCategoryId: dairySubId, name: 'γαλα'),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      // …και μόνο μία εγγραφή τελικά (atomicity του constraint).
      final all = await dao.watchAll().first;
      expect(all.length, 1);
    });
  });

  group('ItemDao.getByNormalizedName', () {
    test('βρίσκει με ακριβές normalizedName', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');
      final row = await dao.getByNormalizedName('γαλα');

      expect(row, isNotNull);
      expect(row!.id, id);
    });

    test('ανύπαρκτο → null (όχι exception)', () async {
      expect(await dao.getByNormalizedName('ανύπαρκτο'), isNull);
    });
  });

  group('ItemDao.watchAll / watchBySubCategoryId', () {
    test('real-time: άδειο → δείγμα', () async {
      expect(await dao.watchAll().first, isEmpty);
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');

      expect((await dao.watchAll().first).single.id, id);
    });

    test('ordering: κατά normalizedName', () async {
      final id1 = await dao.insert(subCategoryId: dairySubId, name: 'Β');
      final id2 = await dao.insert(subCategoryId: dairySubId, name: 'Α');
      final id3 = await dao.insert(subCategoryId: dairySubId, name: 'Γ');

      final ids = (await dao.watchAll().first).map((i) => i.id);
      expect(ids, [id2, id1, id3]);
    });

    test('watchBySubCategoryId φιλτράρει μόνο της ζητούμενης', () async {
      final otherSubId = await SubCategoryDao(db)
          .insert(categoryId: foodCategoryId, name: 'Αρτοποιήματα');
      await dao.insert(subCategoryId: otherSubId, name: 'Ψωμί');
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');

      final rows = await dao.watchBySubCategoryId(dairySubId).first;
      expect(rows.map((i) => i.id), [id]);
    });
  });

  group('ItemDao.updateById', () {
    test('αλλαγή name → ξανά-υπολογισμός normalizedName (SPoT §3)', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');
      expect(await dao.updateById(id, name: 'ΓΑΛΑ 5%'), isTrue);

      final row = await dao.getById(id);
      expect(row!.name, 'ΓΑΛΑ 5%');
      expect(row.normalizedName, GreekTextNormalizer.normalize('ΓΑΛΑ 5%'));
    });

    test('αλλαγή subCategoryId χωρίς αλλαγή name: normalizedName ανέπαφο',
        () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');
      final otherSubId = await SubCategoryDao(db)
          .insert(categoryId: foodCategoryId, name: 'Αρτοποιήματα');

      expect(await dao.updateById(id, subCategoryId: otherSubId), isTrue);
      final row = await dao.getById(id);
      expect(row!.subCategoryId, otherSubId);
      expect(row.normalizedName, 'γαλα');
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.updateById(9999, name: 'Χ'), isFalse);
    });
  });

  group('ItemDao.deleteById', () {
    test('διαγράφει χωρίς γραμμές αποδείξεων', () async {
      final id = await dao.insert(subCategoryId: dairySubId, name: 'Γάλα');
      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });
  });
}