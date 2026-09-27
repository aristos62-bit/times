/// Unit tests για `ReceiptDao.watchTotals*` (§2.1 · Φάση 5 Βήμα 2).
///
/// SQL aggregation πάνω στο αποθηκευμένο `lineTotalCents` (SPoT §3 — καθαρά,
/// μετά έκπτωση): SUM + GROUP BY + WHERE περιόδου (from inclusive / to
/// exclusive) · `INNER JOIN` (ομάδες χωρίς πωλήσεις δεν γίνονται φέτες) ·
/// σειρά totalCents desc, name asc · κενή περίοδος → [].
/// In-memory βάση — ΚΑΝΕΝΑ widget (real async, όχι FakeAsync).
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

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
  late ReceiptLineDao lineDao;

  late int unitId;
  late int categoryId;
  late int subId;
  late int itemId;
  late int secondItemId;
  late int supplierId;
  late int secondSupplierId;

  setUp(() async {
    db = inMemoryDb();
    dao = ReceiptDao(db);
    lineDao = ReceiptLineDao(db);

    unitId = await UnitDao(db).insert(name: 'Τεμάχιο', abbreviation: 'τεμ');
    categoryId = await CategoryDao(db).insert(name: 'ΤΡΟΦΙΜΑ');
    subId = await SubCategoryDao(db)
        .insert(categoryId: categoryId, name: 'Γαλακτοκομικά');
    itemId = await ItemDao(db).insert(subCategoryId: subId, name: 'Γάλα');
    secondItemId =
        await ItemDao(db).insert(subCategoryId: subId, name: 'Τυρί');
    supplierId = await SupplierDao(db).insert(name: 'Μάρκος');
    secondSupplierId = await SupplierDao(db).insert(name: 'Ερμής');
  });

  tearDown(() async => await db.close());

  /// Απόδειξη 1 γραμμής (χωρίς έκπτωση): σύνολο = priceCents × quantity.
  Future<int> seedReceipt({
    required DateTime date,
    required int supplier,
    required int item,
    double quantity = 2,
    int priceCents = 199,
    int discountCents = 0,
  }) async {
    final id = await dao.insert(date: date, supplierId: supplier);
    await lineDao.insert(
      receiptId: id,
      itemId: item,
      unitId: unitId,
      quantity: quantity,
      priceCents: priceCents,
      discountCents: discountCents,
    );
    return id;
  }

  group('watchTotalsBySupplier', () {
    test('κενή βάση → []', () async {
      expect(
        await dao
            .watchTotalsBySupplier(
              from: DateTime(2026, 1, 1),
              to: DateTime(2026, 2, 1),
            )
            .first,
        isEmpty,
      );
    });

    test('αθροίζει γραμμές ανά προμηθευτή (SUM stored lineTotalCents)', () async {
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);
      await seedReceipt(
        date: DateTime(2026, 1, 6),
        supplier: supplierId,
        item: secondItemId,
        quantity: 1,
        priceCents: 50,
      );
      await seedReceipt(
        date: DateTime(2026, 1, 7),
        supplier: secondSupplierId,
        item: itemId,
        quantity: 1,
        priceCents: 100,
      );

      final rows = await dao
          .watchTotalsBySupplier(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows.length, 2);
      expect(rows.singleWhere((r) => r.supplierId == supplierId).totalCents, 199 * 2 + 50);
      expect(rows.singleWhere((r) => r.supplierId == secondSupplierId).totalCents, 100);
      expect(rows.first.supplierName, 'Μάρκος');
    });

    test('φίλτρο περιόδου: εκτός ορίων αποκλείονται', () async {
      await seedReceipt(date: DateTime(2026, 1, 10), supplier: supplierId, item: itemId);
      await seedReceipt(date: DateTime(2025, 12, 31), supplier: supplierId, item: itemId);
      await seedReceipt(date: DateTime(2026, 2, 1), supplier: supplierId, item: itemId);

      final rows = await dao
          .watchTotalsBySupplier(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows.single.totalCents, 199 * 2);
    });

    test('όρια: from inclusive · to exclusive', () async {
      await seedReceipt(date: DateTime(2026, 1, 1), supplier: supplierId, item: itemId);
      await seedReceipt(date: DateTime(2026, 1, 31, 23, 59), supplier: supplierId, item: itemId);
      await seedReceipt(date: DateTime(2026, 2, 1), supplier: supplierId, item: itemId);

      final rows = await dao
          .watchTotalsBySupplier(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows.single.totalCents, 199 * 2 * 2);
    });

    test('σειρά: totalCents desc, μετά name asc', () async {
      await seedReceipt(
        date: DateTime(2026, 1, 5),
        supplier: secondSupplierId,
        item: itemId,
        quantity: 1,
        priceCents: 100,
      );
      await seedReceipt(
        date: DateTime(2026, 1, 6),
        supplier: supplierId,
        item: itemId,
        quantity: 1,
        priceCents: 100,
      );

      final rows = await dao
          .watchTotalsBySupplier(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      // Ισοβαθμία 100/100 → αλφαβητικά: Ερμής πριν Μάρκος.
      expect(rows.map((r) => r.supplierName), ['Ερμής', 'Μάρκος']);
    });

    test('προμηθευτής χωρίς αποδείξεις αποκλείεται (INNER)', () async {
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);

      final rows = await dao
          .watchTotalsBySupplier(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows.map((r) => r.supplierId), [supplierId]);
    });

    test('σύνολα καθαρά με έκπτωση (Δ-stat §3)', () async {
      await seedReceipt(
        date: DateTime(2026, 1, 5),
        supplier: supplierId,
        item: itemId,
        quantity: 2,
        priceCents: 199,
        discountCents: 50,
      );

      final rows = await dao
          .watchTotalsBySupplier(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows.single.totalCents, (199 - 50) * 2);
    });

    test('re-emit: νέο save ξανα-εκπέμπει', () async {
      final firstSnapshot = Completer<void>();
      final secondSnapshot = Completer<void>();
      var emissions = 0;
      final sub = dao
          .watchTotalsBySupplier(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .listen(
        (_) {
          emissions++;
          if (emissions == 1) firstSnapshot.complete();
          if (emissions == 2) secondSnapshot.complete();
        },
        onError: (Object e, StackTrace s) {
          if (!firstSnapshot.isCompleted) firstSnapshot.completeError(e, s);
          if (!secondSnapshot.isCompleted) secondSnapshot.completeError(e, s);
        },
      );
      addTearDown(sub.cancel);

      await firstSnapshot.future.timeout(const Duration(seconds: 2));
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);
      await secondSnapshot.future.timeout(const Duration(seconds: 2));
      expect(emissions, 2);
    });
  });

  group('watchTotalsByCategory', () {
    test('αθροίζει είδη κατηγορίας · άλλη κατηγορία εκτός', () async {
      final otherCategoryId = await CategoryDao(db).insert(name: 'ΠΟΤΑ');
      final otherSubId = await SubCategoryDao(db)
          .insert(categoryId: otherCategoryId, name: 'Καφές');
      final otherItemId =
          await ItemDao(db).insert(subCategoryId: otherSubId, name: 'Εσπρέσο');
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);
      await seedReceipt(
        date: DateTime(2026, 1, 6),
        supplier: supplierId,
        item: otherItemId,
        quantity: 1,
        priceCents: 300,
      );

      final rows = await dao
          .watchTotalsByCategory(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows.length, 2);
      expect(
        rows.singleWhere((r) => r.categoryId == categoryId).totalCents,
        199 * 2,
      );
      expect(
        rows.singleWhere((r) => r.categoryId == otherCategoryId).totalCents,
        300,
      );
    });

    test('γραμμές εκτός περιόδου δεν μετρούν', () async {
      await seedReceipt(date: DateTime(2026, 3, 5), supplier: supplierId, item: itemId);

      final rows = await dao
          .watchTotalsByCategory(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows, isEmpty);
    });
  });

  group('watchTotalsBySubCategory', () {
    test('αθροίζει είδη υποκατηγορίας · άλλη υποκατηγορία εκτός', () async {
      final otherSubId = await SubCategoryDao(db)
          .insert(categoryId: categoryId, name: 'Αλλαντικά');
      final otherItemId =
          await ItemDao(db).insert(subCategoryId: otherSubId, name: 'Ζαμπόν');
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);
      await seedReceipt(
        date: DateTime(2026, 1, 6),
        supplier: supplierId,
        item: otherItemId,
        quantity: 1,
        priceCents: 250,
      );

      final rows = await dao
          .watchTotalsBySubCategory(
            from: DateTime(2026, 1, 1),
            to: DateTime(2026, 2, 1),
          )
          .first;

      expect(rows.length, 2);
      expect(rows.singleWhere((r) => r.subCategoryId == subId).totalCents, 199 * 2);
      expect(
        rows.singleWhere((r) => r.subCategoryId == otherSubId).totalCents,
        250,
      );
    });
  });

  group('watchTopItems', () {
    test('αθροίζει ανά είδος με σειρά totalCents desc', () async {
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);
      await seedReceipt(
        date: DateTime(2026, 1, 6),
        supplier: supplierId,
        item: secondItemId,
        quantity: 5,
        priceCents: 100,
      );

      final rows = await dao
          .watchTopItems(from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1))
          .first;

      expect(rows.map((r) => r.itemId), [secondItemId, itemId]);
      expect(rows.first.totalCents, 500);
    });

    test('γραμμή 0,00 € μετρά (έγκυρη, Βήμα 7)', () async {
      await lineDao.insert(
        receiptId: await dao.insert(
          date: DateTime(2026, 1, 5),
          supplierId: supplierId,
        ),
        itemId: itemId,
        unitId: unitId,
        quantity: 0.004,
        priceCents: 1,
      );

      final rows = await dao
          .watchTopItems(from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1))
          .first;

      expect(rows.single.totalCents, 0);
      expect(rows.single.itemName, 'Γάλα');
    });

    test('είδος χωρίς πωλήσεις αποκλείεται (INNER)', () async {
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);

      final rows = await dao
          .watchTopItems(from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1))
          .first;

      expect(rows.map((r) => r.itemId), [itemId]);
    });

    test('μετονομασία είδους φαίνεται (join, όχι snapshot)', () async {
      await seedReceipt(date: DateTime(2026, 1, 5), supplier: supplierId, item: itemId);
      await ItemDao(db).updateById(itemId, name: 'Γάλα φρέσκο');

      final rows = await dao
          .watchTopItems(from: DateTime(2026, 1, 1), to: DateTime(2026, 2, 1))
          .first;

      expect(rows.single.itemName, 'Γάλα φρέσκο');
    });
  });
}
