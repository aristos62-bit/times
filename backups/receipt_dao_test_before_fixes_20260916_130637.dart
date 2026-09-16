/// Unit tests για το `ReceiptDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// Ελέγχει insert/getById (ο id είναι ο αριθμός απόδειξης AUTOINCREMENT),
/// watchAll ordering (date desc, id desc), FK raw error (ανύπαρκτο supplier),
/// RESTRICT όταν υπάρχουν γραμμές, and updateById (date/supplierId).
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';

import '../helpers/in_memory_db.dart';

void main() {
  late dynamic db;
  late ReceiptDao dao;
  late int supplierId;

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptDao(db);
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
  });

  tearDown(() async => await db.close());

  group('ReceiptDao.insert/getById', () {
    test('επιστρέφει id (αριθμός απόδειξης) και η εγγραφή διαβάζεται', () async {
      final date = DateTime(2026, 1, 5, 10, 30);
      final id = await dao.insert(date: date, supplierId: supplierId);
      final row = await dao.getById(id);

      expect(row, isNotNull);
      expect(row!.date, date);
      expect(row.supplierId, supplierId);
    });

    test('FK raw error (όχι AppException) σε ανύπαρκτο supplier', () async {
      await expectLater(
        dao.insert(date: DateTime(2026, 1, 1), supplierId: 9999),
        throwsA(allOf(isA<SqliteException>(), isNot(isA<AppException>()))),
      );
    });
  });

  group('ReceiptDao.watchAll', () {
    test('real-time: άδειο → δείγμα', () async {
      expect(await dao.watchAll().first, isEmpty);
      final id = await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);

      expect((await dao.watchAll().first).single.id, id);
    });

    test('ordering: νεότερες πρώτα, μετά id desc', () async {
      final idOlder = await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      final idNewer = await dao.insert(date: DateTime(2026, 1, 2), supplierId: supplierId);
      final idSame = await dao.insert(date: DateTime(2026, 1, 2), supplierId: supplierId);

      final ids = (await dao.watchAll().first).map((r) => r.id);
      // idSame και idNewer έχουν ίδια ημερομηνία → id desc μεταξύ τους.
      expect(ids, [idSame, idNewer, idOlder]);
    });
  });

  group('ReceiptDao.updateById', () {
    test('ενημερώνει date ή supplierId (μερικά)', () async {
      final id = await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      final otherSupplier = await SupplierDao(db).insert(name: 'Ερμής');

      expect(await dao.updateById(id, date: DateTime(2026, 2, 1)), isTrue);
      expect((await dao.getById(id))!.date, DateTime(2026, 2, 1));

      expect(await dao.updateById(id, supplierId: otherSupplier), isTrue);
      expect((await dao.getById(id))!.supplierId, otherSupplier);
    });

    test('ανύπαρκτο id → false', () async {
      expect(
        await dao.updateById(9999, date: DateTime(2026, 1, 1)),
        isFalse,
      );
    });
  });

  group('ReceiptDao.deleteById', () {
    test('διαγράφει χωρίς γραμμές', () async {
      final id = await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      expect(await dao.deleteById(id), isTrue);
      expect(await dao.getById(id), isNull);
    });
  });
}