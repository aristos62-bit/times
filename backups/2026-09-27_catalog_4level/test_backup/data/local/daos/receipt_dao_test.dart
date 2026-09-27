/// Unit tests για το `ReceiptDao` (Φάση 1, Βήμα 2) — CRUD + streams.
///
/// Ελέγχει insert/getById (ο id είναι ο αριθμός απόδειξης AUTOINCREMENT),
/// watchAll ordering (date desc, id desc), FK raw error (ανύπαρκτο supplier),
/// CASCADE στη διαγραφή (σβήνει και γραμμές), updateById (date/supplierId).
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:times/core/errors/app_exceptions.dart';
import 'package:times/data/local/daos/category_dao.dart';
import 'package:times/data/local/daos/item_dao.dart';
import 'package:times/data/local/daos/receipt_dao.dart';
import 'package:times/data/local/daos/receipt_line_dao.dart';
import 'package:times/data/local/daos/sub_category_dao.dart';
import 'package:times/data/local/daos/supplier_dao.dart';
import 'package:times/data/local/daos/unit_dao.dart';

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

  /// Δημιουργεί Unit + Category + SubCategory + Item και επιστρέφει
  /// (itemId, unitId) — απαραίτητα για την εισαγωγή γραμμής απόδειξης.
  Future<({int itemId, int unitId})> seedItemWithUnit() async {
    final unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    final subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    final itemId = await ItemDao(db).insert(
          subCategoryId: subId,
          name: 'Γάλα',
          defaultUnitId: unitId,
        );
    return (itemId: itemId, unitId: unitId);
  }

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

    test('CASCADE: διαγραφή απόδειξης σβήνει και τις γραμμές της (§3)', () async {
      final unitDao = UnitDao(db);
      final unitId = await unitDao.insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
      final categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
      final subId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
      final itemId = await ItemDao(db).insert(
        subCategoryId: subId,
        name: 'Γάλα',
        defaultUnitId: unitId,
      );
      final receiptId = await dao.insert(
        date: DateTime(2026, 1, 1),
        supplierId: supplierId,
      );
      final lineId = await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: itemId,
        unitId: unitId,
        quantity: 2,
        priceCents: 199,
      );

      await dao.deleteById(receiptId);

      expect(await dao.getById(receiptId), isNull);
      expect(
        await db.select(db.receiptLines).get(),
        isEmpty,
        reason: 'CASCADE: οι γραμμές πρέπει να σβηστούν μαζί με την απόδειξη',
      );
      // Το item παραμένει (RESTRICT μόνο σε γραμμές → items §2.3).
      expect(await ItemDao(db).getById(itemId), isNotNull);
      expect(lineId, greaterThan(0));
    });
  });

  group('ReceiptDao.watchRecentSummaries (Φάση 3, Βήμα 7)', () {
    test('κενή βάση → κενή λίστα', () async {
      expect(await dao.watchRecentSummaries(limit: 10).first, isEmpty);
    });

    test('επιστρέφει κεφαλίδα + supplierName + γραμμές χωρίς γραμμές (0/0)',
        () async {
      final id = await dao.insert(
        date: DateTime(2026, 1, 5, 10, 30),
        supplierId: supplierId,
      );

      final summaries = await dao.watchRecentSummaries(limit: 10).first;
      final summary = summaries.single;

      expect(summary.id, id);
      expect(summary.date, DateTime(2026, 1, 5, 10, 30));
      expect(summary.supplierId, supplierId);
      expect(summary.supplierName, 'Μάρκος');
      expect(summary.lineCount, 0);
      expect(summary.totalCents, 0);
    });

    test('lineCount + totalCents = SUM(lineTotalCents) (SQL aggregation §2.1)',
        () async {
      final seed = await seedItemWithUnit();
      final receiptId =
          await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      final lineDao = ReceiptLineDao(db);
      await lineDao.insert(
        receiptId: receiptId,
        itemId: seed.itemId,
        unitId: seed.unitId,
        quantity: 2,
        priceCents: 199,
      );
      await lineDao.insert(
        receiptId: receiptId,
        itemId: seed.itemId,
        unitId: seed.unitId,
        quantity: 1,
        priceCents: 50,
      );

      final summary =
          (await dao.watchRecentSummaries(limit: 10).first).single;

      expect(summary.lineCount, 2);
      expect(summary.totalCents, 199 * 2 + 50);
    });

    test('lineTotalCents == 0 (edge §5: 0,01 € × 0,004) → σύνολο 0 €',
        () async {
      final seed = await seedItemWithUnit();
      final receiptId =
          await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      await ReceiptLineDao(db).insert(
        receiptId: receiptId,
        itemId: seed.itemId,
        unitId: seed.unitId,
        quantity: 0.004,
        priceCents: 1,
      );

      final summary =
          (await dao.watchRecentSummaries(limit: 10).first).single;

      expect(summary.lineCount, 1);
      expect(summary.totalCents, 0, reason: '0,01 € × 0,004 → round() = 0');
    });

    test('ordering: date desc, μετά id desc (ίδια σειρά με watchAll)', () async {
      final idOlder =
          await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);
      final idNewer =
          await dao.insert(date: DateTime(2026, 1, 2), supplierId: supplierId);
      final idSame =
          await dao.insert(date: DateTime(2026, 1, 2), supplierId: supplierId);

      final ids = (await dao.watchRecentSummaries(limit: 10).first)
          .map((s) => s.id)
          .toList();
      expect(ids, [idSame, idNewer, idOlder]);
    });

    test('limit: επιστρέφει μόνο τις N νεότερες', () async {
      final idNewest =
          await dao.insert(date: DateTime(2026, 1, 3), supplierId: supplierId);
      final idMiddle =
          await dao.insert(date: DateTime(2026, 1, 2), supplierId: supplierId);
      await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);

      final summaries = await dao.watchRecentSummaries(limit: 2).first;
      expect(summaries.map((s) => s.id).toList(), [idNewest, idMiddle]);
    });

    test('re-emit: το stream ξανα-εκπέμπει όταν αλλάζουν τα δεδομένα', () async {
      final snapshots = <int>[]; // πλήθος summaries ανά snapshot
      final firstSnapshot = Completer<void>();
      final secondSnapshot = Completer<void>();
      final sub = dao.watchRecentSummaries(limit: 10).listen(
        (value) {
          snapshots.add(value.length);
          if (snapshots.length == 1) {
            firstSnapshot.complete();
          } else if (snapshots.length == 2) {
            secondSnapshot.complete();
          }
        },
        onError: (Object e, StackTrace s) {
          if (!firstSnapshot.isCompleted) firstSnapshot.completeError(e, s);
          if (!secondSnapshot.isCompleted) secondSnapshot.completeError(e, s);
        },
      );
      addTearDown(sub.cancel);

      await firstSnapshot.future.timeout(const Duration(seconds: 2));
      expect(snapshots.first, 0);

      await dao.insert(date: DateTime(2026, 1, 1), supplierId: supplierId);

      await secondSnapshot.future.timeout(const Duration(seconds: 2));
      expect(snapshots.last, 1);
    });
  });
}