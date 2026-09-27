/// Unit tests για το `SupplierDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// SPoT §3: `normalizedName` υπολογίζεται εσωτερικά με
/// `GreekTextNormalizer.normalize(name)` και ξανά στο updateById όταν αλλάζει
/// το name. Ελέγχει UNIQUE duplicate (raw), FK raw error, RESTRICT όταν
/// υπάρχουν αποδείξεις, και ότι το `createdAt` ρυθμίζεται από τη βάση.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/core/utils/greek_text_normalizer.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late SupplierDao dao;

  // SPoT §3: το normalizedName καταλήγει σε τελικό «σ» (U+03C3) —
  // ΕΝΑ final sigma (ς/U+03C2) μετατρέπεται σε σ (GreekTextNormalizer).
  const normalizedMarkos = 'μαρκο\u03C3';

  setUp(() {
    db = inMemoryDb();
    dao = SupplierDao(db);
  });

  tearDown(() async => await db.close());

  group('SupplierDao.insert (SPoT normalizedName)', () {
    test('«Μάρκος» → normalizedName «μαρκος» (τελικό σ, όχι ς)', () async {
      final id = await dao.insert(name: 'Μάρκος');
      final row = await dao.getById(id);

      expect(row!.name, 'Μάρκος');
      expect(row.normalizedName, normalizedMarkos);
    });

    test('createdAt ρυθμίζεται από τη βάση (default)', () async {
      final id = await dao.insert(name: 'Ερμής');
      expect((await dao.getById(id))!.createdAt, isNotNull);
    });

    test('UNIQUE duplicate raw error: «Μάρκος» vs «μάρκος»', () async {
      await dao.insert(name: 'Μάρκος');
      await expectLater(
        dao.insert(name: 'μάρκος'),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );

      final all = await dao.watchAll().first;
      expect(all.length, 1);
    });
  });

  group('SupplierDao.getByNormalizedName', () {
    test('βρίσκει με ακριβές normalizedName', () async {
      final id = await dao.insert(name: 'Μάρκος');
      final row = await dao.getByNormalizedName(normalizedMarkos);
      expect(row, isNotNull);
      expect(row!.id, id);
    });

    test('ανύπαρκτο → null', () async {
      expect(await dao.getByNormalizedName('ανύπαρκτο'), isNull);
    });
  });

  group('SupplierDao.watchAll', () {
    test('real-time: άδειο → δείγμα', () async {
      expect(await dao.watchAll().first, isEmpty);
      final id = await dao.insert(name: 'Μάρκος');
      expect((await dao.watchAll().first).single.id, id);
    });

    test('ordering: κατά normalizedName', () async {
      final idB = await dao.insert(name: 'Β');
      final idA = await dao.insert(name: 'Α');
      final idC = await dao.insert(name: 'Γ');

      final ids = (await dao.watchAll().first).map((s) => s.id);
      expect(ids, [idA, idB, idC]);
    });
  });

  group('SupplierDao.updateById', () {
    test('αλλαγή name → ξανά-υπολογισμός normalizedName (SPoT §3)', () async {
      final id = await dao.insert(name: 'Μάρκος');
      expect(await dao.updateById(id, name: 'ΜάρκοςΜ'), isTrue);

      final row = await dao.getById(id);
      expect(row!.name, 'ΜάρκοςΜ');
      expect(
        row.normalizedName,
        GreekTextNormalizer.normalize('ΜάρκοςΜ'),
      );
    });

    test('ανύπαρκτο id → false', () async {
      expect(await dao.updateById(9999, name: 'Χ'), isFalse);
    });
  });

  group('SupplierDao.deleteById', () {
    test('διαγράφει χωρίς αποδείξεις', () async {
      final id = await dao.insert(name: 'Μάρκος');
      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });

    test('RESTRICT raw error αν υπάρχουν αποδείξεις', () async {
      final id = await dao.insert(name: 'Μάρκος');
      await ReceiptDao(db).insert(date: DateTime(2026, 1, 1), supplierId: id);

      await expectLater(
        dao.deleteById(id),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
      expect(await dao.getById(id), isNotNull);
    });
  });
}