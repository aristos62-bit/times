/// Unit tests για το `UnitDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// Ελέγχει insert (default `allowsDecimal=false`, explicit true), watchAll
/// (ordering name), updateById (μερική ενημέρωση name/abbreviation/allowsDecimal),
/// deleteById, και ότι η απαλοιφή είναι δυνατή όταν δεν υπάρχουν εξαρτήσεις.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:times/data/local/daos/unit_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late UnitDao dao;

  setUp(() {
    db = inMemoryDb();
    dao = UnitDao(db);
  });

  tearDown(() async => await db.close());

  group('UnitDao.insert/getById', () {
    test('default allowsDecimal = false', () async {
      final id = await dao.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final row = await dao.getById(id);

      expect(row!.name, 'Τεμάχιο');
      expect(row.abbreviation, 'τεμ');
      expect(row.allowsDecimal, isFalse);
    });

    test('explicit allowsDecimal = true', () async {
      final id = await dao.insert(
        name: 'Κιλό',
        abbreviation: 'κιλ',
        allowsDecimal: true,
      );

      expect((await dao.getById(id))!.allowsDecimal, isTrue);
    });
  });

  group('UnitDao.watchAll', () {
    test('real-time: άδειο → δείγμα', () async {
      expect(await dao.watchAll().first, isEmpty);

      final id = await dao.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      expect((await dao.watchAll().first).single.id, id);
    });

    test('ordering: αλφαβητικά κατά name', () async {
      final idB = await dao.insert(name: 'Β', abbreviation: 'β');
      final idA = await dao.insert(name: 'Α', abbreviation: 'α');
      final idC = await dao.insert(name: 'Γ', abbreviation: 'γ');

      final ids = (await dao.watchAll().first).map((u) => u.id);
      expect(ids, [idA, idB, idC]);
    });
  });

  group('UnitDao.updateById', () {
    test('μερική ενημέρωση όλων των πεδίων', () async {
      final id = await dao.insert(name: 'ΠΑΛΙΟ', abbreviation: 'π');
      final row = await dao.updateById(
        id,
        name: 'ΝΕΟ',
        abbreviation: 'ν',
        allowsDecimal: true,
      );

      expect(row, isTrue);
      final updated = await dao.getById(id);
      expect(updated!.name, 'ΝΕΟ');
      expect(updated.abbreviation, 'ν');
      expect(updated.allowsDecimal, isTrue);
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.updateById(999, name: 'Χ'), isFalse);
    });
  });

  group('UnitDao.deleteById', () {
    test('διαγράφει, getById → null', () async {
      final id = await dao.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });
  });
}